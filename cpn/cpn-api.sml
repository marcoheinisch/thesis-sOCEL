(*fun experimental() = (OS.Process.system "python main.py")*)


fun init_pycpn() = 
let
	val _ = openConnection("Con1", "localhost", 9999);
	val _ = send("Con1", "init", stringEncode)
in
	receive("Con1", stringDecode)
end;

fun close_pycpn() = (
	send("Con1", "close", stringEncode);
	closeConnection("Con1")
);


fun call(call_id:string, param_str:string):string = 
let
	val call_str = "call_v1%" ^ call_id ^ "%" ^ param_str
in
	if not API_ENABLED then
		"0.0"
	else (
		send("Con1", call_str, stringEncode);
		receive("Con1", stringDecode)
	)
end;