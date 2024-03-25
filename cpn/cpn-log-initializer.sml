(* reuses code from https://doi.org/10.5281/zenodo.8289899 **)


val SEP = ";";
val OUTPUT_PATH = "../data/socel-csv/";

(**************************************************************************************************)
(* Configure OCEL                                                                                 *)
(**************************************************************************************************)

val EVENT_TYPES = ["SplitSteelSheet", "HeatSteelSheet", "FormSteelSheet", "CoatPart", "CuttMalePart", "CuttFemalePart", "CheckMalePart", "CheckFemalePart", "AssembleHinge", "PackHinges", "MoveParts"];
val OBJECT_TYPES = ["SteelCoil", "SteelSheet", "FormedPart", "MalePart", "FemalePart", "SteelPin", "Hinge", "HingePack", "Workstation","Machine","Facility", "Worker"];

fun eas_by_type(a: EventType) = 
   if a="SplitSteelSheet" 
      then ["p_duration[s]", "s_co2e[kg]", "i_electric-from-grid-de[kWh]", "i_steel-waste-to-recycle[kg]"] else 
   if a="HeatSteelSheet" 
      then ["p_duration[s]", "s_co2e[kg]", "i_electric-from-grid-de[kWh]", "i_gas_input[Wh]", "i_emission-of-burn[Wh]"] else 
   if a="FormSteelSheet" 
      then ["p_duration[s]", "s_co2e[kg]", "i_electric-from-grid-de[kWh]"] else 
   if a="CoatPart"  
      then ["p_duration[s]", "s_co2e[kg]", "i_electric-from-grid-de[kWh]", "i_coating-material[kg]", "i_coating-material-waste[kg]"] else 
   if a="CuttMalePart" orelse a="CuttFemalePart" 
      then ["p_duration[s]", "s_co2e[kg]", "i_electric-from-grid-de[kWh]", "i_compressed-air[m3]", "i_gas-n2-used[m3]","i_gas-n2-emiited-to-air[m3]", "i_steel-waste[kg]"] else 
   if a="CheckMalePart" orelse a="CheckFemalePart" 
      then ["p_duration[s]", "s_co2e[kg]", "i_compressed-air[m3]"] else 
   if a="AssembleHinge" 
      then ["p_duration[s]", "s_co2e[kg]"] else 
   if a="PackHinges" 
      then ["p_duration[s]", "s_co2e[kg]", "i_cardboard-box[kg]"] else 
   if a="MoveParts" 
      then ["p_duration[s]"] else 
   ["debug_default"];
	
fun oas_by_type(ot: ObjectType) = 
	if ot="SteelCoil" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "p_init-len[cm]", "p_width[cm]", "i_material-cold-rolled-steel[kg]", "s_co2e[kg]", "i_steel-waste-to-recycle[kg]"] else 
	if ot="SteelSheet" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "s_co2e[kg]"] else
	if ot="FormedPart" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "s_co2e[kg]"] else 
	if ot="MalePart" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "s_co2e[kg]", "i_steel-waste[kg]"] else
	if ot="FemalePart" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "s_co2e[kg]", "i_steel-waste[kg]"] else 
	if ot="SteelPin" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "i_material-steel-pin[kg]","s_co2e[kg]"] else 
	if ot="Hinge" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "s_co2e[kg]"] else 
	if ot="HingePack" 
      then ["p_mass[kg]", "p_material[EN10130:2006]", "s_co2e[kg]"] else 
   if ot="Workstation" 
      then ["P_electric-from-grid-de[kWh]", "P_compressed-air[m3]"] else
   if ot="Machine" 
      then ["P_electric-from-grid-de[kWh]", "P_gas-from-grid-de[m3]"] else
   if ot="Worker" 
      then ["m_metadata"] else
   if ot="Facility" 
      then ["m_metadata"] else
   ["debug_deafult"];

(* identity as mapping functions *)

fun event_map_type(a: EventType) =
   a;
fun object_map_type(ot: ObjectType) =
   ot;

(**************************************************************************************************)
(* Other                                                                                          *)
(**************************************************************************************************)

(* helper functions *)

fun list2string([]) = ""|
list2string(x::l) = x ^ (if l=[] then "" else SEP) ^ list2string(l);

fun write_event_map_types(file_id, []) = () | write_event_map_types(file_id, et::ets) = 
(
   TextIO.output(file_id, list2string([et, event_map_type(et)])); 
   TextIO.output(file_id, "\n"); write_event_map_types(file_id, ets)
) 

fun write_object_map_types(file_id, []) = () | write_object_map_types(file_id, ot::ots) = 
(
   TextIO.output(file_id, list2string([ot, object_map_type(ot)])); 
   TextIO.output(file_id, "\n"); write_object_map_types(file_id, ots)
)

(* table initializations *)

fun create_event_table() = 
let
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "event.csv")
   val _ = TextIO.output(file_id, list2string(["ocel_id", "ocel_type"])) 
   val _ = TextIO.output(file_id, "\n")
in
   TextIO.closeOut(file_id)
end;

fun create_object_table() = 
let
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "object.csv")
   val _ = TextIO.output(file_id, list2string(["ocel_id", "ocel_type"])) 
   val _ = TextIO.output(file_id, "\n")
in
   TextIO.closeOut(file_id)
end;

fun create_event_object_table() = 
let
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "event_object.csv")
   val _ = TextIO.output(file_id, list2string(["ocel_event_id", "ocel_object_id", "ocel_qualifier"])) 
   val _ = TextIO.output(file_id, "\n")
in
   TextIO.closeOut(file_id)
end;

fun create_object_object_table() = 
let
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "object_object.csv")
   val _ = TextIO.output(file_id, list2string(["ocel_source_id", "ocel_target_id", "ocel_qualifier"])) 
   val _ = TextIO.output(file_id, "\n")
in
   TextIO.closeOut(file_id)
end;

fun create_event_map_type_table() = 
let
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "event_map_type.csv")
   val _ = TextIO.output(file_id, list2string(["ocel_type", "ocel_type_map"])) 
   val _ = TextIO.output(file_id, "\n")
   val _ = write_event_map_types(file_id, EVENT_TYPES)
in
   TextIO.closeOut(file_id)
end;

fun create_object_map_type_table() = 
let
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "object_map_type.csv")
   val _ = TextIO.output(file_id, list2string(["ocel_type", "ocel_type_map"])) 
   val _ = TextIO.output(file_id, "\n")
   val _ = write_object_map_types(file_id, OBJECT_TYPES)
in
   TextIO.closeOut(file_id)
end;

fun create_event_type_table(a: EventType) = 
let
   val emt = event_map_type(a)
   val eas = eas_by_type(a)
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "event_" ^ emt ^ ".csv")
   val _ = TextIO.output(file_id, list2string(["ocel_id", "ocel_time"]^^eas)) 
   val _ = TextIO.output(file_id, "\n")
in
   TextIO.closeOut(file_id)
end;

fun create_event_type_tables([]) = () | create_event_type_tables(a::a_s) = 
(
   create_event_type_table(a); 
   create_event_type_tables(a_s)
);

fun create_object_type_table(ot: ObjectType) = 
let
   val omt = object_map_type(ot)
   val oas = oas_by_type(ot)
   val file_id = TextIO.openOut(OUTPUT_PATH ^ "object_" ^ omt ^ ".csv")
   val _ = TextIO.output(file_id, list2string(["ocel_id", "ocel_time", "ocel_changed_field"]^^oas))
   val _ = TextIO.output(file_id, "\n")
in
   TextIO.closeOut(file_id)
end;

fun create_object_type_tables([]) = () | create_object_type_tables(ot::ots) = 
(
   create_object_type_table(ot); 
   create_object_type_tables(ots)
);

(* create all tables *)

fun create_logs() = (
   create_event_table(); 
   create_object_table(); 
   create_event_object_table(); 
   create_object_object_table(); 
   create_event_map_type_table(); 
   create_object_map_type_table(); 
   create_event_type_tables(EVENT_TYPES); 
   create_object_type_tables(OBJECT_TYPES)
);
