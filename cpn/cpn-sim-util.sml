(* Helper functions *)

fun roundNth (x: real, n:int): real =
let
    val scale = Math.pow(10.0, real n)
in
    real (round(x * scale)) / scale
end;

fun ran_entry(value, max_diff) = 
let 
    val ran = ran_beta((value-max_diff), (value+max_diff), 5.0, 5.0)
    val ran_ge0 = if ran < 0.0001 then 0.0 else ran
in
    ran_ge0
end;

(***********************)
(* General COnfig      *)
(***********************)

(* Simualtaion dys *)
val COIL_N = 4

(* In CPN model defined: val SIMULATION_N = i.e. 3000; *)

val SIMULATION_N = (3000 *COIL_N) div 4

val SHEET_LENGTH            = 3.00 (* in cm *)
val SHEET_WIDTH             = 3.00 (* in cm *)
val SHEET_THICKNESS         = 0.30 (* in cm *)
val MATERIAL_DENSTIY        = 0.00784 (* in kg/cm3 <--- 7.84 g/cm3 *)

val COIL_LENGTH = roundNth(real(SIMULATION_N)*SHEET_LENGTH*2.01 / real(COIL_N), 2)
val PART_BATCH_N = 200

val SHEET_LENGTH_TOLERANCE  = 0.05
val SHEET_LENGTH_MAX = SHEET_LENGTH + SHEET_LENGTH_TOLERANCE
val CUTT_LENGTH = 0.06 (* OPTIMAL *)

(* Hinge Packing*)
val PACKED_HINGES = 10
val MASS_PACKAGING = 0.1


(* Simulate Cutting *)
fun sheet_mass_by_length(l) = roundNth(l * MATERIAL_DENSTIY * SHEET_THICKNESS * SHEET_WIDTH, 5);
fun sim_length(l) = roundNth(normal(l, 0.016*0.016), 4); (* mean: l=SHEET_LENGTH, sd: 0.01 => p_reject ~= 0.05 *)



(*CPN: (m2, len2, m3,len3) = sim_cutt(m1, len1) *)
fun sim_cutt(m1: real, len1: real) =
let
    val raw_len2 = sim_length(SHEET_LENGTH)
    val len2 = if (raw_len2 > SHEET_LENGTH + SHEET_LENGTH_TOLERANCE * 2.0) then SHEET_LENGTH_MAX else raw_len2
    val m2 = sheet_mass_by_length(len2)
    val lenWaste = sim_length(CUTT_LENGTH)
    val mWaste = sheet_mass_by_length(CUTT_LENGTH)
in
    (m2, len2, m1 - (m2 + mWaste), len1 - (len2 + lenWaste), mWaste)
end;

fun sim_electricity_cutt() =
let
    val kWh_cutt = ran_entry(7.206,0.2)  (*by https://doi.org/10.1016/j.procir.2016.03.095*)
in
    roundNth(kWh_cutt, 5)
end;


(* Quality Gate criterias *)
fun check_mass(real_mass) = 
let
    val ideal_mass = MATERIAL_DENSTIY * SHEET_THICKNESS * SHEET_WIDTH * SHEET_LENGTH 
    val diff = abs(real_mass - ideal_mass)
    val tollerance = MATERIAL_DENSTIY * SHEET_THICKNESS * SHEET_WIDTH * SHEET_LENGTH_TOLERANCE 
in
    diff < tollerance
end;


(* Hinge Assambly*)
fun sim_hingemass(m1, m2, m3) =
let
    val mass = roundNth(m1 + m2 + m3 + MASS_PACKAGING, 4)
in
    mass
end;


(* Compressed Air *)
fun sim_compressed_air(duration_s:real) =
let
    val air_per_second = 0.38 / 60.0 (* https://www.hodgeclemco.co.uk/air-consumption-chart/*)
    val air = ran_entry(air_per_second * duration_s, 5.0*air_per_second)
in
    roundNth(air, 3)
end;

fun electric_from_compressed_air(air_m3) =
let
    val kWh_per_m3 = 0.57 (* ow efficient, by https://doi.org/10.3929/ethz-a-009959904*)
    val energy = ran_entry(air_m3 * kWh_per_m3, 0.01*kWh_per_m3)
in
    roundNth(energy, 5)
end;


(* Cardboard, by measured example*)
val CARDBOARD_MASS_FOR10 = 0.050
fun sim_cardboard_mass() =
let
    val mass = roundNth(CARDBOARD_MASS_FOR10 * real(PACKED_HINGES) / 10.0, 3)
in
    mass
end;


(* paint usage, by https://www.onropes.co.uk/coating-calculations*)
val COAT_WASTE_RATE = 0.2
val TSR = 5.0 (* in m2/l *)
fun sim_coat_usage() =
let
    val surface_m2 = SHEET_WIDTH * SHEET_LENGTH * 2.0 / (100.0 * 100.0)
    val paint_used_l = roundNth(surface_m2 / TSR, 4)
    val paint_wasted_l = roundNth(paint_used_l * COAT_WASTE_RATE, 4)
in
    (paint_used_l, paint_wasted_l, surface_m2)
end;


(* LAser gas  + electric, by 10.1016/j.cirpj.2020.08.004*)
val GAS_N2_PER_SECOND = 22.0 / (60.0*60.0)
fun sim_gas_n2(duration_s) =
let
    val mass = roundNth(GAS_N2_PER_SECOND * duration_s, 3)
in
    mass
end;


fun p_electricity_laser_a(t_start, t_end, status) =
let
    val kW_laser_on = 5.5
    val kW_laser_idle = 0.2
    val time_diff = (t_end - t_start) / 3600.0
    val energy_usage = 
        case status of
            "on" => kW_laser_on * time_diff
            | "idle" => kW_laser_idle * time_diff
            | "startup" => kW_laser_idle * time_diff
            | "shutdown" => kW_laser_idle * time_diff
            | "off" => 0.0
            | _ => raise Fail "Invalid status (p_electricity_laser_a)"
in
    roundNth(energy_usage, 7)
end;

fun p_electricity_coating(t_start, t_end, status) =
let
    val kW_coating_on = 3.0
    val kW_coating_idle = 0.01
    val time_diff = (t_end - t_start) / 3600.0
    val energy_usage = 
        case status of
            "on" => kW_coating_on * time_diff
            | "idle" => kW_coating_idle * time_diff
            | "startup" => kW_coating_idle * time_diff
            | "shutdown" => kW_coating_idle * time_diff
            | "off" => 0.0
            | _ => raise Fail "Invalid status (p_electricity_coating)"
in 
    roundNth(energy_usage, 7)
end;

fun p_electricity_forming(t_start, t_end, status) =
let
    val kW_startup =  0.8 (*measured by 10.1007/s00170-021-08368-6*)
    val kW_idle = 2.0 
    val kW_froming = 3.0
    val time_diff = (t_end - t_start) / 3600.0
    val energy_usage = 
        case status of
            "on" => kW_froming * time_diff
            | "idle" => kW_idle * time_diff
            | "startup" => kW_startup * time_diff
            | "shutdown" => kW_startup * time_diff
            | "off" => 0.0
            | _ => raise Fail "Invalid status (p_electricity_coating)"
in 
    roundNth(energy_usage, 7)
end;

fun sim_electricity_heating(duration) = 
let
    val kW_vent = 0.08
    val time_diff = duration / 3600.0
    val energy_usage = kW_vent * time_diff
in 
    roundNth(energy_usage, 5)
end;

val WASTE_RATE_CUTT = 0.12
fun sim_waste_cutt_male(mass) = 
let
    val waste = mass * WASTE_RATE_CUTT *2.0
in 
    roundNth(waste, 5)
end;
fun sim_waste_cutt_female(mass) = 
let
    val waste = mass * WASTE_RATE_CUTT
in 
    roundNth(waste, 5)
end;

val WASTE_RATE_Form = 0.03
fun sim_waste_form(mass) = 
let
    val waste = mass * WASTE_RATE_Form
in 
    roundNth(waste, 5)
end;

fun p_gas_heating(t_start, t_end, status) =
let
    val j_per_kgC = 420.0
    val diff_temp_C = 200.0
    val energy_theoretical_J = (MATERIAL_DENSTIY * SHEET_THICKNESS * SHEET_WIDTH * SHEET_LENGTH) * diff_temp_C * j_per_kgC

    val time_diff = (t_end - t_start) / 3600.0

    val energy_usage = 
        case status of
            "on" => energy_theoretical_J / 3600.0
            | "idle" => energy_theoretical_J / 3600.0
            | "startup" => energy_theoretical_J * 3.0 / 3600.0
            | "shutdown" => 0.0
            | "off" => 0.0
            | _ => raise Fail "Invalid status (p_electricity_coating)"
in 
    roundNth(energy_usage, 5)
end;

