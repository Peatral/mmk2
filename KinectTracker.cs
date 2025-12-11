using System;
using System.Collections.Generic;
using Godot;

namespace godotkinect;

[GlobalClass]
public partial class KinectTracker: Node3D
{
	public void UpdatePositions(Vector3[] positions)
	{

		var sortedPositions = new List<Vector3>(positions);
		sortedPositions.Sort((a, b) => a.X.CompareTo(b.X));
		for (var i = sortedPositions.Count; i < GetChildCount(); i++)
		{
			GetChild(i).QueueFree();
		}

		for (var i = 0; i < sortedPositions.Count; i++)
		{
			MeshInstance3D child;
			if (i < GetChildCount())
			{
				child = (MeshInstance3D)GetChild(i);
			}
			else
			{
				child = new MeshInstance3D();
				child.Mesh = GD.Load<Mesh>("res://foot_mesh.tres");
				AddChild(child);
			}

			if (positions[i].DistanceSquaredTo(child.Position) < 1.5 || child.Position == Vector3.Zero)
			{
				child.Position = child.Position.Slerp(positions[i], 0.5f);
			}
		}
	}    
}
