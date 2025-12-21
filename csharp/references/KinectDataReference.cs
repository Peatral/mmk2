using Godot;
using Godot.Collections;

namespace godotkinect.csharp.references;

[GlobalClass]
public partial class KinectDataReference : Resource
{
	private Array<KinectData> _value = [];

	[Signal]
	public delegate void ValueChangedEventHandler(Array<KinectData> value);

	public Array<KinectData> Value
	{
		get => _value;
		set
		{
			_value = value;
			EmitSignal(SignalName.ValueChanged, value);
		}
	}
}
