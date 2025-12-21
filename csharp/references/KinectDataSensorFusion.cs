using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

namespace godotkinect.csharp.references;

[GlobalClass]
public partial class KinectDataSensorFusion : Node
{
	private readonly Godot.Collections.Dictionary<int, Array<Vector3>> _peerData = new();
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

	private void UpdateValue(Array<Vector3> value)
	{
		if (GetMultiplayer() == null || GetMultiplayer().MultiplayerPeer == null ||
			GetMultiplayer().MultiplayerPeer.GetConnectionStatus() != MultiplayerPeer.ConnectionStatus.Connected)
		{
			if (Output != null) Output.Value = value;
			return;
		}

		if (GetMultiplayer().IsServer())
		{
			_peerData[1] = value;
			ProcessFusion();
		}
		else
		{
			RpcId(1, MethodName.ServerReceiveData, value);
		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = false)]
	private void ServerReceiveData(Array<Vector3> data)
	{
		if (!GetMultiplayer().IsServer()) return;

		var senderId = GetMultiplayer().GetRemoteSenderId();
		_peerData[senderId] = data;
		ProcessFusion();
	}

	[Rpc(CallLocal = true)]
	private void ClientReceiveData(Array<Vector3> data)
	{
		if (Output != null) Output.Value = data;
	}

	private void ProcessFusion()
	{
		var connectedPeers = new HashSet<int>(GetMultiplayer().GetPeers()) { 1 };

		var keysToRemove = _peerData.Keys.Where(k => !connectedPeers.Contains(k)).ToList();
		foreach (var k in keysToRemove) _peerData.Remove(k);

		var fusedPoints = new List<Vector3>();
		var processedPoints = new HashSet<(int PeerId, int Index)>();

		var allPoints = new List<(int PeerId, int Index, Vector3 Position)>();
		foreach (var kvp in _peerData)
		{
			allPoints.AddRange(kvp.Value.Select((t, i) => (kvp.Key, i, t)));
		}

		foreach (var current in allPoints)
		{
			if (processedPoints.Contains((current.PeerId, current.Index))) continue;

			var cluster = new List<Vector3> { current.Position };
			processedPoints.Add((current.PeerId, current.Index));

			var current1 = current;
			var otherPeers = _peerData.Keys.Where(k => k != current1.PeerId).ToList();

			foreach (var otherPeerId in otherPeers)
			{
				var minDistanceSq = MergeDistance * MergeDistance;
				var bestMatchIndex = -1;
				var bestMatchPos = Vector3.Zero;

				for (var j = 0; j < allPoints.Count; j++)
				{
					var potentialMatch = allPoints[j];
					
					if (potentialMatch.PeerId != otherPeerId) continue;
					if (processedPoints.Contains((potentialMatch.PeerId, potentialMatch.Index))) continue;

					var distSq = current.Position.DistanceSquaredTo(potentialMatch.Position);
					if (distSq < minDistanceSq)
					{
						minDistanceSq = distSq;
						bestMatchIndex = j;
						bestMatchPos = potentialMatch.Position;
					}
				}

				if (bestMatchIndex == -1) continue;

				cluster.Add(bestMatchPos);
				processedPoints.Add((allPoints[bestMatchIndex].PeerId, allPoints[bestMatchIndex].Index));
			}

			var avg = Vector3.Zero;
			foreach (var p in cluster) avg += p;
			if (cluster.Count > 0) avg /= cluster.Count;
			fusedPoints.Add(avg);
		}

		Rpc(MethodName.ClientReceiveData, new Array<Vector3>(fusedPoints));
	}
}
