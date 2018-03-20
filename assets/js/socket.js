// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import { Socket, Presence } from "phoenix"



// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.


window.active = false;
var data = {
    myTurn: false,
    mySign: "O",
    userId: makeUuid(5),
    room: "ASDF"
}
let socket = new Socket("/socket", { params: { user_id: data.userId } })

$(document).ready(function() {


    console.log("Active is : " + window.active)
    document.getElementById("title").innerHTML = "USER ID : " + data.userId;
    data.room = document.getElementById("game").innerHTML

    console.log("Joining room " + data.room + " as user :" + data.userId)

    let presences = {}




    socket.connect()


    // Now that you are connected, you can join channels with a topic:
    let channel = socket.channel("room:" + data.room, {})


    $(".block").on("click", function() {
        console.log("Active is : " + window.active)
        if (window.active == true && $(this).is(':empty')) {
            $(this).html("<span class='my-mark'>X</span>");
            window.active = false;
            channel.push('next_move', { position: $(this).index() })
        }
        console.log("Now window.active is : ", window.active)
    })



    channel.join()
        .receive("ok", resp => { console.log("Joined successfully", resp) })
        .receive("error", resp => { console.log("Unable to join", resp) })

    let onlineUsers


    channel.on("presence_state", state => {
        presences = Presence.syncState(presences, state, onJoin, onLeave)
    })

    channel.on("presence_diff", diff => {
        presences = Presence.syncDiff(presences, diff, onJoin, onLeave)
    })

    channel.on("next_move", function(message) {
        if (message.user === data.userId) {
            $(".block").eq(message.position).html("O");
            console.log("Got approval for next move")
            window.active = true;
        } else {
            console.log("Got approval for other guy " + message.user + " and our user_id = " + data.userId)
        }
    })

    channel.on("won", function(message) {
        if (message.user === data.userId) {
            alert("You win!!!")
        } else {
        	$(".block").eq(message.position).html("O");
            alert("You lose!!")
        }
    })

    let usersOnline = 0;

    // detect if user has joined for the 1st time or from another tab/device
    let onJoin = (id, current, newPres) => {
        console.log("On join")
    }
    // detect if user has left from all tabs/devices, or is still present
    let onLeave = (id, current, leftPres) => {
        console.log("user left")
    }
})




function makeUuid(length) {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

    for (var i = 0; i < length; i++)
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}

export default socket