function log(msg) {
	var log = $('<td/>').addClass('chat-message');
	log.html(msg);
	$("#log").prepend($('<tr/>').addClass('message').append(log));
}

function initWs(path) {
	var ws = new WebSocket(path);
    ws.onopen = function () {
		log('connected');
    };
    ws.onclose = function (ev) {
		log('closed');
    };
    ws.onmessage = function (ev) {
		log(ev.data);
		$("#message").val('');
    };
    ws.onerror = function (ev) {
		console.log(ev);
		log('error: ' + ev.data);
    };
    $("#form").submit(function () {
		if ( ! $("#username").val() ) {
			alert('名前を入力して下さい。');
			return false;
		}
		ws.send($("#username").val() + ': ' + $("#message").val());
		return false;
    });
}
