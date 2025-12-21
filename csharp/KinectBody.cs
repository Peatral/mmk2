using Godot;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectBody(KinectData data) : RefCounted
{
	public KinectData TrackedData { get; set; } = data;
	public ulong LastSeenTime { get; set; }
}
