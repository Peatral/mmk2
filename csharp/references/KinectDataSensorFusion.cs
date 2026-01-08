using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

namespace godotkinect.csharp.references;

[GlobalClass]
public partial class KinectDataSensorFusion : Node
{
	private readonly Godot.Collections.Dictionary<int, Array<KinectData>> _peerData = new();
	private KinectDataReference _input;

	[Export] public float MergeDistance { get; set; } = 0.5f;

	[Export]
	public KinectDataReference Input
	{
		get => _input;
		set
		{
			if (_input != null) _input.ValueChanged -= UpdateValue;
			_input = value;
			if (_input != null) _input.ValueChanged += UpdateValue;
		}
	}

	[Export] public KinectDataReference Output { get; set; }

	private void UpdateValue(Array<KinectData> value)
	{
		if (GetMultiplayer() == null || GetMultiplayer().MultiplayerPeer == null ||
			GetMultiplayer().MultiplayerPeer.GetConnectionStatus() != MultiplayerPeer.ConnectionStatus.Connected)
		{
			if (Output != null) Output.Value = value;
			return;
		}

		if (GetMultiplayer().IsServer())
		{
			_peerData[1] = new Array<KinectData>(value);
			ProcessFusion();
		}
		else
		{
			var serialized = new Array<Dictionary>(value.Select(SerializeKinectData));
			RpcId(1, MethodName.ServerReceiveData, serialized);
		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false)]
	private void ServerReceiveData(Array<Dictionary> data)
	{
		if (!GetMultiplayer().IsServer()) return;

		var senderId = GetMultiplayer().GetRemoteSenderId();
		var deserialized = new Array<KinectData>(data.Select(DeserializeKinectData));
		_peerData[senderId] = deserialized;
		ProcessFusion();
	}

	private void ProcessFusion()
	{
		var connectedPeers = new HashSet<int>(GetMultiplayer().GetPeers()) { 1 };

		var keysToRemove = _peerData.Keys.Where(k => !connectedPeers.Contains(k)).ToList();
		foreach (var k in keysToRemove) _peerData.Remove(k);

		var fusedPoints = new Array<KinectData>();
		var processedPoints = new HashSet<(int PeerId, int Index)>();

		var allPoints = new List<(int PeerId, int Index, KinectData Data)>();
		foreach (var kvp in _peerData)
		{
			allPoints.AddRange(kvp.Value.Select((t, i) => (kvp.Key, i, t)));
		}

		foreach (var current in allPoints)
		{
			if (processedPoints.Contains((current.PeerId, current.Index))) continue;

			var cluster = new List<KinectData> { current.Data };
			processedPoints.Add((current.PeerId, current.Index));

			var current1 = current;
			var otherPeers = _peerData.Keys.Where(k => k != current1.PeerId).ToList();

			foreach (var otherPeerId in otherPeers)
			{
				var minDistanceSq = MergeDistance * MergeDistance;
				var bestMatchIndex = -1;
				KinectData bestMatch = null;

				for (var j = 0; j < allPoints.Count; j++)
				{
					var potentialMatch = allPoints[j];
					
					if (potentialMatch.PeerId != otherPeerId) continue;
					if (processedPoints.Contains((potentialMatch.PeerId, potentialMatch.Index))) continue;

					var distSq = current.Data.Position.DistanceSquaredTo(potentialMatch.Data.Position);
					if (distSq < minDistanceSq)
					{
						minDistanceSq = distSq;
						bestMatchIndex = j;
						bestMatch = potentialMatch.Data;
					}
				}

				if (bestMatchIndex == -1 || bestMatch == null) continue;

				cluster.Add(bestMatch);
				processedPoints.Add((allPoints[bestMatchIndex].PeerId, allPoints[bestMatchIndex].Index));
			}

			if (cluster.Count == 1)
			{
				fusedPoints.Add(cluster[0]);
				continue;
			}

			var avg = cluster.Aggregate(Vector3.Zero, (current2, p) => current2 + p.Position);
			if (cluster.Count > 0) avg /= cluster.Count;
			fusedPoints.Add(new KinectData(avg, cluster.Any(data => data.ArmRaised)));
		}

		if (Output != null) Output.Value = fusedPoints;
	}

	private static Dictionary SerializeKinectData(KinectData data)
	{
		return new Dictionary
		{
			{ "Position", data.Position },
			{ "ArmRaised", data.ArmRaised }
		};
	}

	private static KinectData DeserializeKinectData(Dictionary dict)
	{
		return new KinectData(
			dict["Position"].AsVector3(),
			dict["ArmRaised"].AsBool()
		);
	}
}
