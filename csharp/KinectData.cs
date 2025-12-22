using Godot;

namespace godotkinect.csharp;

[GlobalClass]
public partial class KinectData(Vector3 position, bool armRaised) : RefCounted
{
	[Signal]
	public delegate void ArmRaisedChangedEventHandler(bool armRaised);

	[Signal]
	public delegate void PositionChangedEventHandler(Vector3 position);

	public Vector3 Position { get; private set; } = position;
	public bool ArmRaised { get; private set; } = armRaised;

	public void Apply(KinectData data)
	{
		if (!Position.Equals(data.Position))
		{
			Position = data.Position;
			EmitSignal(SignalName.PositionChanged, Position);
		}

		if (ArmRaised != data.ArmRaised)
		{
			ArmRaised = data.ArmRaised;
			EmitSignal(SignalName.ArmRaisedChanged, ArmRaised);
		}
	}
}