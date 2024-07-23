# GodotMetaMaskLogin
 A blazing-quick user-oriented MetaMask login system for Godot multiplayer games.

![1](https://github.com/user-attachments/assets/7d021de6-510f-49ce-ad9b-f996ff575476)

This login system has been designed first and foremost for Desktop Windows applications that would require a MetaMask / Public ETH address as a logging method option for a server-controlled multiplayer environment.

## Requirements

For the example to work as it stands, one needs a C#-enabled (mono) version of Godot 4.2.2 (see [here](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html)) as well as Visual Studio 2022.
In order for the C# part to run, you will need to install NuGet packages Nethereum.Util and Nethereum.Signer.

Optionally, you will need npm v10.7.0 and Node.js v20.15.1 if you want to modify and host your own version of the browser-client part, although this is not needed as you can use https://auth.numdev.live (see below)

## Workflow

The login system starts with peers connected in a regular Godot setting. This could be a chat room, lobby, or multiplayer game system. From there, it goes as follows:

* Login button is clicked by user 
* The server provides to the client and stores a record of a timestamp, a random number as well as the Godot multiplayer peerid
* The default browser of the client is sent to https://auth.numdev.live (or optionally your own host)
* The frontend triggers a MetaMask signing request authenticating the three pieces of information
* A Websocket connection is established with Godot to bring back the signature into the Godot environment
* The client sends the signature proof to the server using Godot RPCs
* The server verifies the validity of the login proof using 8 different security features (time elapsed, elliptical curve signature validity, peer authenticity, etc.)
* If all requirements are met, the server informs the client that they are logged in and the client sees a "Log off" button as well as his public ETH address as a confirmation of his identity.

All of this happens in less than a second.

# Security features

Before approving a login proof, the server checks that:
* the user's peerID is the same at submission of the authentication proof than it was at the moment of the initial request to log in.
* a record was made of the time at which the login request was initiated and does not allow a resolution of it after more than 30 seconds have elapsed.
* the message signed was formed according to its standard (i.e. "I am peer X requesting ...").
* the elliptic curve signature has been performed by an entity having access to the private key of the account (MetaMask).
* the user bringing in the signature is the same as the one who requested the login.
* the user bringing in the signature is the same as the one who signed with MetaMask (by displaying the Peerid to the user during the signature process).
* a server-generated random number is in the possession of the multiplayer peer making the login request and the signer of the authorization.
* the three items (the random generated number, the peerid and the timestamp) were present in the signed message.

It should be noted that no feature has been implemented yet keeping a malicious actor from succeeding at a login attempt once, but with a random public address that he does not control. Of course because of the nature of the blockchain, such an attempt would lead to a public address that has no coins on it, so it doesn't matter from a blockchain security perspective, but it should be taken into account when integrating this system to your games.

## Example

An example implementation of GodotMetaMaskLogin can be readily executed in Godot (Main.tscn). Make sure that your Godot Editor binary is C#-enabled and that the Nethereum packages have been added in Visual Studio 2022. Under Debug in Godot > Run Multiple Instances > Run 2 Instances will allow you to run two instances of the program, and one will naturally acquire the role of server during debugging. When moving code to production, you will need to remove those features which are meant only for a server presence to be simulated during debugging.

![2](https://github.com/user-attachments/assets/45510fe4-bac9-4206-9a78-ffa22ac9814a)

![3](https://github.com/user-attachments/assets/fc5060b1-bf81-409d-8546-63f9d1a22dbe)

![4](https://github.com/user-attachments/assets/44cbd48c-933b-47f6-a01a-bbac81f02b8a)

![5](https://github.com/user-attachments/assets/6f1be058-9456-4578-ace9-d1676eaa0c4c)

You will notice that the login system uses URL-encoding of parameters to pass data to the signature component of MetaMask. These items are not particularly secret, they are simply security features allowing the server to remain more strict in its approval of signature (for instance by rejecting any signature that has taken more than 30 seconds to generate). 

![6](https://github.com/user-attachments/assets/5dc4ad4a-a3c6-4d97-8773-282c00147b1f)

## Optional Vite frontend hosting

Because there is no server-side storing of information outside of the Godot server, the frontend really is just a generic piece of software that guides the browser toward delivering the Metamask signature to the Godot application. Therefore, you do not have to host your own copy of the frontend. You can leave the program as is and it will send users to https://auth.numdev.live and gather the correct information back to Godot. However, you may choose to generate your own version so you can use your own URL, and perhaps change the logo on the web frontend for that of your own game. In this case, you'll need to work from the /MetaMaskFE folder, which contains a Vite template that asks the user for the MetaMask signature.

```
npm install
npm run build
```

The files for the frontend will be generated in /dist.

## Other Applications

Although I have developed this system with Desktop Godot games in mind, in principle, the frontend can be reused in many different contexts and the Godot part of the code could be rewritten for other languages to obtain a similar degree of security in other contexts.

## License

Free-to-use and modify with attribution to NumDev2310.
