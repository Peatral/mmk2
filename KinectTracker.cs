using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

namespace godotkinect;

[GlobalClass]
public partial class KinectTracker : Node3D
{
	private class TrackedBody
	{
		private static int _nextId;
		public int Id { get; } = _nextId++;
		public Vector3 Position { get; set; }
		public MeshInstance3D Mesh { get; }
		public ulong LastSeenTime { get; set; }

		public TrackedBody(Vector3 position, MeshInstance3D mesh)
		{
			Position = position;
			Mesh = mesh;
		}
	}

	private readonly List<TrackedBody> _trackedBodies = new();
	private ulong _lastUpdateTime;

	[Export] public float MatchThreshold { get; set; } = 1.5f;

	[Export] public float SecondsToLive { get; set; } = 0.5f; // How many seconds a body can be lost before being removed

	[Export] public float SlerpSpeed { get; set; } = 5f; // Speed of interpolation

	public void UpdateBodies(Vector3[] newPositions)
	{
		var currentTime = Time.GetTicksMsec();
		var deltaTime = _lastUpdateTime > 0 ? (currentTime - _lastUpdateTime) / 1000.0f : 0;
		_lastUpdateTime = currentTime;

		var unmatchedPositions = new HashSet<Vector3>(newPositions);
		var matchedBodiesInFrame = new HashSet<TrackedBody>();
		var potentialMatches = new List<Tuple<TrackedBody, Vector3, float>>();

		foreach (var body in _trackedBodies)
		{
			foreach (var pos in newPositions)
			{
				var distanceSq = body.Position.DistanceSquaredTo(pos);
				if (distanceSq < MatchThreshold * MatchThreshold)
				{
					potentialMatches.Add(new Tuple<TrackedBody, Vector3, float>(body, pos, distanceSq));
				}
			}
		}

		potentialMatches.Sort((a, b) => a.Item3.CompareTo(b.Item3));

		foreach (var match in potentialMatches)
		{
			var body = match.Item1;
			var pos = match.Item2;

			if (matchedBodiesInFrame.Contains(body) || !unmatchedPositions.Contains(pos))
			{
				continue;
			}

			body.Position = pos;
			body.LastSeenTime = currentTime;
			matchedBodiesInFrame.Add(body);
			unmatchedPositions.Remove(pos);
		}

		var bodiesToRemove = _trackedBodies
			.Where(b => currentTime - b.LastSeenTime > (ulong)(SecondsToLive * 1000)).ToList();
		foreach (var body in bodiesToRemove)
		{
			body.Mesh.QueueFree();
			_trackedBodies.Remove(body);
		}

		foreach (var pos in unmatchedPositions)
		{
			var mesh = new MeshInstance3D
			{
				Mesh = GD.Load<Mesh>("res://foot_mesh.tres"),
				Position = pos
			};
			AddChild(mesh);

			var newBody = new TrackedBody(pos, mesh)
			{
				LastSeenTime = currentTime
			};
			_trackedBodies.Add(newBody);
		}

		if (deltaTime > 0)
		{
			// Using an exponential decay for frame-rate independent interpolation
			var slerpFactor = 1.0f - (float)Math.Exp(-SlerpSpeed * deltaTime);
			foreach (var body in _trackedBodies)
			{
				body.Mesh.Position = body.Mesh.Position.Slerp(body.Position, slerpFactor);
			}
		}
	}
}
