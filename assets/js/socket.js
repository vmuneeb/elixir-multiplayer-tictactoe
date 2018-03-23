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
let message = $('#message-input')
let chatMessages = document.getElementById("chat-messages")
let title = document.getElementById("title")

$(document).ready(function() {


    //document.getElementById("title").innerHTML = "USER ID : " + data.userId;
    data.room = document.getElementById("game").innerHTML

    console.log("Joining room " + data.room + " as user :" + data.userId)

    let presences = {}
    message.focus();
    let nickName = data.userId

    message.on('keypress', event => {
        if (event.keyCode == 13) {
            channel.push('message:new', {
                message: message.val(),
                user: nickName
            })
            message.val("")
        }
    });





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
        .receive("ok", resp => {
            showMessage("Joined successfully. Waiting for Player 2<br> <span><a href='/'> click here to open new tab</a> or open this URL from different browser</span>", "success")
            console.log("Joined successfully", resp)
        })
        .receive("error", resp => {
            showMessage("Error joining game", "waring")
            console.log("Unable to join", resp)
        })

    let onlineUsers
    let spectator = false;
    let current_mark = "<span class='mark-1'>X</span>"

    channel.on('message:new', payload => {
        let template = document.createElement("div");
        if (payload.user == nickName)
            payload.user = "You"
        else
            payload.user = "Player 2"

        template.innerHTML = `<b>${payload.user}</b>: 
                           ${payload.message}<br>`
        chatMessages.appendChild(template);
        chatMessages.scrollTop = chatMessages.scrollHeight;
    })


    channel.on("presence_state", state => {
        presences = Presence.syncState(presences, state, onJoin, onLeave)
    })

    channel.on("presence_diff", diff => {
        presences = Presence.syncDiff(presences, diff, onJoin, onLeave)
    })

    channel.on("next_move", function(message) {
        var msg = "";
        if (message.position == 10) {
            msg = "Player 2 Joined", "success";
        }
        if (message.user === data.userId) {
            showMessage(msg + ", Your turn", "success")
            $(".block").eq(message.position).html("O");
            window.active = true;
        } else if(!spectator) {
            showMessage("Wait, Player 2's turn", "danger")
        } else {    
            $(".block").eq(message.position).html(current_mark);
            current_mark = current_mark == "<span class='mark-1'>X</span>" ? "<span class='mark-2'>O</span>" : "<span class='mark-1'>X</span>"
        }
    })

    channel.on("game_over", function(message) {

        if (message.user != data.userId) {
            $(".block").eq(message.position).html("O");
        }

        alert("No possible moves. Game over!!!")
        showMessage("Game over", "danger")
    })

    channel.on("room_full", function(message) {
        if (message.user == data.userId) {
            spectator = true;
            showMessage("Game already started. But you can watch it here", "danger")
        }
    })

    channel.on("player_left", function(message) {
        showMessage("Player left. Game over!!. <a href='/'> click here to start a new game</a>", "danger")
        socket.disconnect();
    })

    channel.on("won", function(message) {
        if (message.user === data.userId) {
            alert("You win!!!")
            showMessage("You win", "success")
        } else {
            if(!spectator) {
                $(".block").eq(message.position).html("O");
                showMessage("You lose!!", "danger")
                alert("You lose!!")
            } else {
                 $(".block").eq(message.position).html(current_mark);
                 showMessage("Game Over", "danger")
            }
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
        // showMessage("Player left. Game over!!. <a href='/'> click here to start a new game</a>", "danger")
        // socket.disconnect();
    }
})


function showMessage(message, type) {
    var className = "alert alert-" + type
    var div = "<div class='" + className + "'>" + message + "</div>"
    title.innerHTML = div;
    //chatMessages.scrollTop = chatMessages.scrollHeight;
}


function makeUuid(length) {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

    for (var i = 0; i < length; i++)
        text += possible.charAt(Math.floor(Math.random() * possible.length));

    return text;
}

export default socket