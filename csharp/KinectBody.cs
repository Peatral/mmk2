using Godot;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectBody(Vector3 position) : RefCounted
{
	public Vector3 Position { get; set; } = position;
	public ulong LastSeenTime { get; set; }
}