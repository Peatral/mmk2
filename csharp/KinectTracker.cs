using System;
using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;
using godotkinect.csharp.references;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectTracker : Resource
{
	[Signal]
	public delegate void BodyTrackedEventHandler(KinectBody body);

	[Signal]
	public delegate void BodyUntrackedEventHandler(KinectBody body);

	private readonly List<KinectBody> _trackedBodies = [];

	private KinectDataReference _kinectDataReference;
	private ulong _lastUpdateTime;
	[Export] private float _matchThreshold = 1.5f;
	[Export] private float _secondsToLive = 3.0f;

	[Export]
	private KinectDataReference KinectDataReference
	{
		get => _kinectDataReference;
		set
		{
			if (_kinectDataReference != null) _kinectDataReference.ValueChanged -= UpdateBodies;
			_kinectDataReference = value;
			if (_kinectDataReference != null) _kinectDataReference.ValueChanged += UpdateBodies;
		}
	}

	public Array<KinectBody> GetTrackedBodies()
	{
		return new Array<KinectBody>(_trackedBodies);
	}

	public void UpdateBodies(Array<KinectData> newData)
	{
		var currentTime = Time.GetTicksMsec();
		_lastUpdateTime = currentTime;

		var unmatchedPositions = new HashSet<KinectData>(newData);
		var matchedBodiesInFrame = new HashSet<KinectBody>();
		var potentialMatches = new List<Tuple<KinectBody, KinectData, float>>();

		foreach (var body in _trackedBodies)
		foreach (var kinectData in newData)
		{
			var distanceSq = body.TrackedData.Position.DistanceSquaredTo(kinectData.Position);
			if (distanceSq < _matchThreshold * _matchThreshold)
				potentialMatches.Add(new Tuple<KinectBody, KinectData, float>(body, kinectData, distanceSq));
		}

		potentialMatches.Sort((a, b) => a.Item3.CompareTo(b.Item3));

		foreach (var match in potentialMatches)
		{
			var body = match.Item1;
			var data = match.Item2;

			if (matchedBodiesInFrame.Contains(body) || !unmatchedPositions.Contains(data)) continue;

			body.TrackedData.Apply(data);
			body.LastSeenTime = currentTime;
			matchedBodiesInFrame.Add(body);
			unmatchedPositions.Remove(data);
		}

		var bodiesToRemove = _trackedBodies
			.Where(b => currentTime - b.LastSeenTime > (ulong)(_secondsToLive * 1000)).ToList();
		foreach (var body in bodiesToRemove)
		{
			_trackedBodies.Remove(body);
			EmitSignal(SignalName.BodyUntracked, body);
		}

		foreach (var data in unmatchedPositions)
		{
			var newBody = new KinectBody(data)
			{
				LastSeenTime = currentTime
			};
			_trackedBodies.Add(newBody);
			EmitSignal(SignalName.BodyTracked, newBody);
		}
	}
}
