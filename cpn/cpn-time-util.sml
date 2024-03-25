(* reuses code from https://doi.org/10.5281/zenodo.8289899 **)


(* TIME unit is seconds*)
val second = 1.0;
val minute = 60.0;
val hour = 60.0*minute;
val day = 24.0*hour;
val week = 7.0*day;

fun Mtime() = ModelTime.time():time;

fun monday_jan_5_2015() = 16440.0*day - 1.0*hour;

fun monday_april_03_2023() = 19450.0*day - 2.0*hour + 7.5*hour ;

fun start_time() = monday_april_03_2023();

fun print_start_time() = Date.fmt "%Y-%m-%d %H:%M:%S" (Date.fromTimeLocal(Time.fromReal(start_time())));

(* TIME OUTPUT mySQL*)
fun t2s(t) = Date.fmt "%Y-%m-%d %H:%M:%S" (Date.fromTimeLocal(Time.fromReal(t+start_time())));

fun tinit2s() = Date.fmt "%Y-%m-%d %H:%M:%S" (Date.fromTimeLocal(Time.fromReal(0.0)));

(* TIME OUTPUT KEYVALUE*)
fun t2s_alt(t) = Date.fmt "%d-%m-%Y %H:%M:%S" (Date.fromTimeLocal(Time.fromReal(t+start_time())));

(* BETA DISTRIBUTION *)
fun ran_beta(low:real,high:real,a:real,b:real) = low + ((high-low)*beta(a,b)):real; 

fun mean_beta(low:real,high:real,a:real,b:real) = low + ((high-low)* (a/(a+b)));

fun mode_beta(low:real,high:real,a:real,b:real) = low + ((high-low)*((a-1.0)/(a+b-2.0)));

fun var_beta(low:real,high:real,a:real,b:real) = ((high-low)*(high-low)* ((a*b)/((a+b)*(a+b)*(a+b+1.0))));

fun stdev_beta(low:real,high:real,a:real,b:real) = Math.sqrt(var_beta(low,high,a,b));



(* TIME FUNCTIONS *)

fun t2date(t) = Date.fromTimeLocal(Time.fromReal(t+start_time()));


fun t2year(t) = Date.year(t2date(t)):int;
fun t2month(t) = Date.month(t2date(t)):Date.month;
fun t2day(t) = Date.day(t2date(t)):int;
fun t2hour(t) = Date.hour(t2date(t)):int;
fun t2minute(t) = Date.minute(t2date(t)):int;
fun t2second(t) = Date.second(t2date(t)):int;
fun t2weekday(t) = Date.weekDay(t2date(t)):Date.weekday;

fun t2monthstr(t) = Date.fmt "%b" (Date.fromTimeLocal(Time.fromReal(t+start_time())));
fun t2weekdaystr(t) = Date.fmt "%a" (Date.fromTimeLocal(Time.fromReal(t+start_time())));

fun remaining_time_hour(t) = hour - ((fromInt(t2minute(t))*minute) + fromInt(t2second(t)));


(* ARRIVAL TIME DISTRIBUTIONS *)

(* arrival time intensities vary from 0.0 to 1.0 and are the product of three factors: yearly influences, weekly influences, and daily influences *)

fun at_month_intensity(m:string) =
case m of 
 "Jan" => 1.0
|"Feb" => 1.0
|"Mar" => 1.0
|"Apr" => 0.3
|"May" => 1.0
|"Jun" => 1.0
|"Jul" => 1.0
|"Aug" => 1.0
|"Sep" => 1.0
|"Oct" => 1.0 
|"Nov" => 1.0
|"Dec" => 1.0
| _ => 1.0;

fun at_weekday_intensity(d:string) =
case d of 
 "Mon" => 1.0
|"Tue" => 1.0
|"Wed" => 1.0
|"Thu" => 1.0
|"Fri" => 1.0
|"Sat" => 0.1
|"Sun" => 0.1
| _ => 1.0;

fun at_hour_intensity(h:int) =
case h of 
 0 => 0.1
|1 => 0.1
|2 => 0.1
|3 => 0.1
|4 => 0.1
|5 => 0.1
|6 => 0.1
|7 => 0.1
|8 => 0.5
|9 => 1.0
|10 => 1.0
|11 => 1.0
|12 => 1.0
|13 => 1.0
|14 => 1.0
|15 => 1.0
|16 => 1.0
|17 => 1.0
|18 => 1.0
|19 => 0.5
|20 => 0.5
|21 => 0.5
|22 => 0.5
|23 => 0.1
| _ => 1.0;
 
(* overall intensity *)
fun at_intensity(t) = at_month_intensity(t2monthstr(t))*at_weekday_intensity(t2weekdaystr(t))*
at_hour_intensity(t2hour(t));

(* Use this function to sample interarrival times: t is the current time and d is the net delay: It moves forward based on intensities: the lower the intensity, the longer the delay in absolute time.*) 
fun rel_at_delay(t,d) = 
if d < 0.0001
   then 0.0
   else if d < remaining_time_hour(t)*at_intensity(t)
        then d/at_intensity(t)
        else rel_at_delay(t+remaining_time_hour(t),
            d-(remaining_time_hour(t)*at_intensity(t)))+hour; 

(* same but now without indicating current time explicitly *)
fun r_at_delay(d) = rel_at_delay(Mtime(),d);

(* the average ratio between effective/net time (parameter d) and delay in actual time*)
val eff_at_factor = r_at_delay(52.0*week)/(52.0*week);

(* normalized interarrival time delay using the ratio above *)
fun norm_rel_at_delay(t,d) = rel_at_delay(t,d/eff_at_factor) ;


(* normalized  interarrival time delay using the ratio above *)
fun norm_r_at_delay(d) = r_at_delay(d/eff_at_factor) ;

(* SERVICE TIME DISTRIBUTIONS *)

(* service time intensities vary from 0.0 to 1.0 and are the product of three factors: yearly influences, weekly influences, and daily influences *)

fun st_month_intensity(m:string) =
case m of 
 "Jan" => 1.0
|"Feb" => 1.0
|"Mar" => 1.0
|"Apr" => 1.0
|"May" => 1.0
|"Jun" => 1.0
|"Jul" => 0.7
|"Aug" => 0.5
|"Sep" => 1.0
|"Oct" => 1.0 
|"Nov" => 1.0
|"Dec" => 1.0
| _ => 1.0;

fun st_weekday_intensity(d:string) =
case d of 
 "Mon" => 0.9
|"Tue" => 1.0
|"Wed" => 1.0
|"Thu" => 1.0
|"Fri" => 0.9
|"Sat" => 0.0
|"Sun" => 0.0
| _ => 1.0;

fun st_hour_intensity(h:int) =
case h of 
 0 => 0.0
|1 => 0.0
|2 => 0.0
|3 => 0.0
|4 => 0.0
|5 => 0.0
|6 => 0.0
|7 => 0.0
|8 => 0.5
|9 => 1.0
|10 => 1.0
|11 => 1.0
|12 => 0.5
|13 => 0.5
|14 => 1.0
|15 => 1.0
|16 => 1.0
|17 => 0.5
|18 => 0.3
|19 => 0.1
|20 => 0.1
|21 => 0.1
|22 => 0.0
|23 => 0.0
| _ => 1.0;
 

fun st_intensity(t) = st_month_intensity(t2monthstr(t))*
st_weekday_intensity(t2weekdaystr(t))*
st_hour_intensity(t2hour(t));


(* Use this function to sample service times: t is the current time and d is the net delay: It moves forward based on intensities: the lower the intensity, the longer the delay in absolute time.*)
fun rel_st_delay(t,d) = 
if d < 0.0001
   then 0.0
   else if d < remaining_time_hour(t)*st_intensity(t)
        then d/st_intensity(t)
        else rel_st_delay(t+remaining_time_hour(t),
            d-(remaining_time_hour(t)*st_intensity(t)))+hour;

(* same but now without indicating current time explicitly *)
fun r_st_delay(d) = rel_st_delay(Mtime(),d);


(* the average ratio between effective/net time (parameter d) and delay in actual time*)
val eff_st_factor = r_st_delay(52.0*week)/(52.0*week);

(* normalized service time delay using the ratio above *)
fun norm_rel_st_delay(t,d) = rel_st_delay(t,d/eff_st_factor) ;

(* normalized service time delay using the ratio above *)
fun norm_r_st_delay(d) = r_st_delay(d/eff_st_factor);

(***********************)
(* Delays              *)
(***********************)
fun ran_delay_normal(min, max) = ran_beta(min, max, 5.0, 5.0);
fun ran_delay_010(value) = ran_beta(((value)*0.9), ((value)*1.1), 3.0, 9.0);
fun ran_delay_002(value) = ran_beta(((value)*0.98), ((value)*1.02), 5.0, 5.0);

fun isPowerOnTime() = 
    let
        val currentTime = Mtime()
        val currentHour = t2hour(currentTime)
    in
        currentHour <= 7
    end;


fun InitialTimeBeforeWork() = ran_delay_010(20.0*60.0);


fun DelayLoadCoil() = ran_delay_010(2.0*60.0);
fun DelaySplitSteelCoil() = 
let
    val delay = if isPowerOnTime() then ran_delay_010(7.0)
    else ran_delay_010(15.0)
in 
    delay
end;

fun DelayUnloadSteelSheet() = ran_delay_010(1.0*60.0);

val HEATING_TARGET_TIME = 15.0*60.0;
fun DurationHeating() = HEATING_TARGET_TIME;
fun DelayHeatSheet() =  ran_delay_010((2.0*60.0+DurationHeating()));

val FORMING_TIME = 5.0;
fun DelayFormSteelSheet() =  ran_delay_002(0.5*60.0+FORMING_TIME);

val COATING_TIME = 5.0*60.0;
fun DelayCoatPart() =  ran_delay_010(10.5*60.0 + COATING_TIME);


val MOVE_TIME = 15.0*60.0;
fun DelayMoveParts() =  ran_delay_010(MOVE_TIME);

fun DelayCuttPartMale() =  ran_delay_002(10.0);
fun DelayCuttPartFemale() =  ran_delay_002(12.5);


fun DelayAfterCuttPart() =  ran_delay_010(0.5*60.0);

fun DelayCheckMalePart() =  ran_delay_010(11.0);
fun DelayCheckFemalePart() =  ran_delay_010(11.0);

val ASSEMBLE_TIME = 5.0;
fun DelayAssembleParts() =  ran_delay_002(ASSEMBLE_TIME+1.0);

fun DelayPackHinges() =  ran_delay_002(30.0);
fun DelayOutputPackedHinges() =  ran_delay_010(5.0);

fun DelayGoTo() = ran_delay_010(7.0*60.0);

fun timeToNext8AM() =
    let
        val currentTime = Mtime() (* Get the current model time *)
        val currentHour = t2hour(currentTime)
        val remainingSecondsCurrentHour = remaining_time_hour(currentTime)

        (* Calculate hours until next 8 AM *)
        val hoursUntilNext8AM = 
            if currentHour < 8 then 8 - currentHour
            else if currentHour = 8 then 0 (* If it's exactly 8 AM, the next 8 AM is 24 hours away *)
            else 24 - currentHour + 8

        (* Calculate total seconds until next 8 AM *)
        val totalSeconds = (real(hoursUntilNext8AM) * hour) + remainingSecondsCurrentHour
    in
        totalSeconds - hour -30.0*60.0(* Subtract an hour because remainingSecondsCurrentHour includes the current hour *)
    end;

fun isWorkdayOver() =
    let
        val currentTime = Mtime() (* Get the current model time *)
        val currentHour = t2hour(currentTime)
    in
        currentHour >= 15
    end;


fun isLunchTime() =
    let
        val currentTime = Mtime()
        val currentHour = t2hour(currentTime)
    in
        currentHour = 12
    end;

fun timeToLunchEnd() = 
    let
        val currentTime = Mtime()
        val currentHour = t2hour(currentTime)
        val remainingSecondsCurrentHour = remaining_time_hour(currentTime)
    in
        remainingSecondsCurrentHour + 1.0*60.0
    end;