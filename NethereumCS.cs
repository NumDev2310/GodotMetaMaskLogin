using Godot;
using Nethereum.Signer;
using Nethereum.Util;
using System.Text;

public partial class NethereumCS : Node
//public class NethereumCS
{
    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
    }

    // Called every frame. 'delta' is the elapsed time since the previous frame.
    public override void _Process(double delta)
    {
    }

    public static string EcRecover(string msg, string sign)
    {
        var signer = new Nethereum.Signer.MessageSigner();
        var message = "\x19" + "Ethereum Signed Message:\n" + msg.Length + msg;
        var address = signer.HashAndEcRecover(message, sign);
        return address;
    }

}