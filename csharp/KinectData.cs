using Godot;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectData(Vector3 position, bool armRaised): Resource
{
	[Export] public Vector3 Position { get; set; } = position;
	[Export] public bool ArmRaised { get; set; } = armRaised;
}