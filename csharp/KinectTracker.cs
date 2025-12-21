using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectTracker : Resource
{
	private readonly List<KinectBody> _trackedBodies = new();
	private ulong _lastUpdateTime;

	[Export] public float MatchThreshold { get; set; } = 1.5f;

	[Export] public float SecondsToLive { get; set; } = 3.0f;
	
	[Signal]
	public delegate void BodyTrackedEventHandler(KinectBody body);
	[Signal]
	public delegate void BodyUntrackedEventHandler(KinectBody body);

	public Array<KinectBody> GetTrackedBodies()
	{
		return new Array<KinectBody>(_trackedBodies);
	}

	public void UpdateBodies(Vector3[] newPositions)
	{
		var currentTime = Time.GetTicksMsec();
		_lastUpdateTime = currentTime;

		var unmatchedPositions = new HashSet<Vector3>(newPositions);
		var matchedBodiesInFrame = new HashSet<KinectBody>();
		var potentialMatches = new List<Tuple<KinectBody, Vector3, float>>();

		foreach (var body in _trackedBodies)
		foreach (var pos in newPositions)
		{
			var distanceSq = body.Position.DistanceSquaredTo(pos);
			if (distanceSq < MatchThreshold * MatchThreshold)
				potentialMatches.Add(new Tuple<KinectBody, Vector3, float>(body, pos, distanceSq));
		}

		potentialMatches.Sort((a, b) => a.Item3.CompareTo(b.Item3));

		foreach (var match in potentialMatches)
		{
			var body = match.Item1;
			var pos = match.Item2;

			if (matchedBodiesInFrame.Contains(body) || !unmatchedPositions.Contains(pos)) continue;

			body.Position = pos;
			body.LastSeenTime = currentTime;
			matchedBodiesInFrame.Add(body);
			unmatchedPositions.Remove(pos);
		}

		var bodiesToRemove = _trackedBodies
			.Where(b => currentTime - b.LastSeenTime > (ulong)(SecondsToLive * 1000)).ToList();
		foreach (var body in bodiesToRemove)
		{
			_trackedBodies.Remove(body);
			EmitSignal(SignalName.BodyUntracked, body);
		}

		foreach (var pos in unmatchedPositions)
		{
			var newBody = new KinectBody(pos)
			{
				LastSeenTime = currentTime
			};
			_trackedBodies.Add(newBody);
			EmitSignal(SignalName.BodyTracked, newBody);
		}
	}
}
