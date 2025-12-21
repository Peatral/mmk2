using Godot;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectData(Vector3 position, bool armRaised): RefCounted
{
	public Vector3 Position { get; } = position;
	public bool ArmRaised { get; } = armRaised;
}