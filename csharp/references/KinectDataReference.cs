using Godot;
using Godot.Collections;

namespace godotkinect.csharp.references;

[GlobalClass]
public partial class KinectDataReference : Resource
{
	private Array<Vector3> _value = [];

	[Signal]
	public delegate void ValueChangedEventHandler(Array<Vector3> value);

	[Export]
	public Array<Vector3> Value
	{
		get => _value;
		set
		{
			_value = value;
			EmitSignal(SignalName.ValueChanged, value);
		}
	}
}
