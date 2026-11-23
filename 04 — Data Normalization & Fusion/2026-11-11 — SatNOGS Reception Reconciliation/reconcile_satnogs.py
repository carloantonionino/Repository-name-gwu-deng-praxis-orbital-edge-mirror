import csv, json, hashlib, pathlib, datetime, collections, re
BASE = pathlib.Path(__file__).resolve().parent
def read_csv(p):
    with p.open(encoding="utf-8-sig",newline="") as f:
        sample=f.read(4096); f.seek(0)
        return list(csv.DictReader(f,dialect=csv.Sniffer().sniff(sample,delimiters=",;\t")))
def utc(value):
    dt=datetime.datetime.fromisoformat(value.replace("Z","+00:00").replace(" ","T"))
    if dt.tzinfo is None: dt=dt.replace(tzinfo=datetime.timezone.utc)
    return dt.astimezone(datetime.timezone.utc).isoformat().replace("+00:00","Z")
def write_csv(name,rows,cols=None):
    cols=cols or list(rows[0])
    with (BASE/"derived"/name).open("w",encoding="utf-8",newline="") as f:
        w=csv.DictWriter(f,fieldnames=cols);w.writeheader();w.writerows(rows)
def null_id(value):
    return "" if str(value).strip().lower() in ["","none","null","nan"] else str(int(float(value)))
qualified=read_csv(BASE/"inputs/OPS_SAT_ACE_100_Witness_Qualification_Register_v01.csv")
witnesses=read_csv(BASE/"inputs/ACE_Observer_Witnesses_100_v01.csv")
returned=read_csv(BASE/"sources/ops-sat_sids_frames.csv")
archive=json.loads((BASE/"inputs/OPS-SAT_2022-01-26_to_2022-01-29_COMPLETE.json").read_text(encoding="utf-8-sig"))
groups=collections.defaultdict(list)
for row in qualified: groups[int(row["source_json_row_1based"])].append(row)
idx=collections.defaultdict(list)
for row in returned:
    idx[(row["Source"],row["Observer/Station"],utc(row["Timestamp"]))].append(row)
def raw_observer_name(s):
    # The archival observer string ends with a 6-character Maidenhead grid.
    return re.sub(r"-[A-Ra-r]{2}[0-9]{2}[A-Xa-x]{2}$","",s)
errors=[];cross=[];matched_ids=set();ace=[]
for source_row, group in sorted(groups.items()):
    old=archive[source_row-1]
    for row in group:
        h=hashlib.sha256(old["frame"].encode("ascii")).hexdigest()
        if h!=row["frame_sha256"]:errors.append({"type":"frame_hash","entity":row["ace_entity"]})
        if utc(old["timestamp"])!=utc(row["radio_witness_utc"]):errors.append({"type":"timestamp","entity":row["ace_entity"]})
        if old["observer"]!=row["observer_as_recorded"]:errors.append({"type":"observer","entity":row["ace_entity"]})
        w=next(x for x in witnesses if x["entity"]==row["ace_entity"])
        if int(w["json_row_1_based"])!=source_row or utc(w["comm_witness_utc"])!=utc(old["timestamp"]):
            errors.append({"type":"secondary_witness_register","entity":row["ace_entity"]})
    key=(old["app_source"],raw_observer_name(old["observer"]),utc(old["timestamp"]))
    candidates=idx.get(key,[])
    status="MATCHED_METADATA" if len(candidates)==1 else "NOT_IN_RETURNED_EXTRACT" if not candidates else "AMBIGUOUS"
    new=candidates[0] if len(candidates)==1 else {}
    original_obs=null_id(old.get("observation_id"))
    if new and original_obs and original_obs!=null_id(new.get("Observation ID")):
        errors.append({"type":"observation_id_mismatch","source_row":source_row})
    if new: matched_ids.add(new["Frame ID"])
    r={
       "source_json_row_1based":source_row,
       "observer_as_recorded":old["observer"],
       "observer_match_name":key[1],
       "source_route":old["app_source"],
       "reception_utc":key[2],
       "ace_row_count":len(group),
       "ace_entities":"|".join(str(x["ace_entity"]) for x in group),
       "archived_frame_sha256":group[0]["frame_sha256"],
       "original_station_id":null_id(old.get("station_id")),
       "original_observation_id":original_obs,
       "match_status":status,
       "returned_frame_id":new.get("Frame ID",""),
       "returned_observation_id":null_id(new.get("Observation ID")),
       "returned_lat":new.get("Lat",""),
       "returned_lon":new.get("Lon",""),
       "match_rule":"Exact UTC reception time + source route + observer name; Network observation ID also checked",
       "payload_identity_status":"Archived payload verified against saved SHA256; returned payload not independently checked (telemetry API requires authentication)"
    }
    cross.append(r)
    for row in group:
        ace.append({"ace_entity":row["ace_entity"],"telemetry_utc":utc(row["telemetry_utc"]),
                    "reception_utc":key[2],"source_json_row_1based":source_row,"source_route":old["app_source"],
                    "observer_as_recorded":old["observer"],"returned_frame_id":r["returned_frame_id"],
                    "match_status":status,"original_observation_id":original_obs})
all_returned=[]
for row in returned:
    hit=[x for x in cross if x["returned_frame_id"]==row["Frame ID"]]
    all_returned.append({**row,"selected_reception_match":"YES" if hit else "NO",
                         "selected_source_json_row_1based":hit[0]["source_json_row_1based"] if hit else "",
                         "linked_ace_rows":hit[0]["ace_row_count"] if hit else 0})
obs_summary=[];site_conflicts=[];artifact_links=[]
for oid in ["5369438","5375671"]:
    p=BASE/"observations"/("observation_"+oid+".json")
    obj=json.loads(p.read_text())
    if obj["id"]!=int(oid) or obj["norad_cat_id"]!=44878: errors.append({"type":"wrong_observation","id":oid})
    cm=json.loads(obj["client_metadata"]) if obj.get("client_metadata") else {}
    params=cm.get("radio",{}).get("parameters",{})
    recs=[r for r in returned if null_id(r.get("Observation ID"))==oid]
    selected=[r for r in cross if r["original_observation_id"]==oid]
    out={"observation_id":oid,"station_id":obj["ground_station"],"station_name":obj["station_name"],
         "norad_cat_id":obj["norad_cat_id"],"start_utc":obj["start"],"end_utc":obj["end"],"reported_status":obj["status"],
         "returned_frame_count":len(recs),"selected_reception_count":len(selected),
         "selected_ace_rows":sum(r["ace_row_count"] for r in selected),
         "api_station_lat":obj.get("station_lat"),"api_station_lon":obj.get("station_lng"),"api_station_alt_m":obj.get("station_alt"),
         "client_lat":cm.get("latitude"),"client_lon":cm.get("longitude"),"client_elevation_m":cm.get("elevation"),
         "csv_lat":recs[0]["Lat"],"csv_lon":recs[0]["Lon"],
         "frequency_hz":obj.get("observation_frequency"),"configured_baud":params.get("baudrate"),
         "radio_device":params.get("soapy-rx-device"),"demod_artifact_links":len(obj.get("demoddata",[])),
         "iq_dump_enabled":params.get("enable-iq-dump"),"waterfall_url":obj.get("waterfall"),
         "audio_archive_url":obj.get("archive_url"),"api_url":"https://network.satnogs.org/api/observations/"+oid+"/",
         "observation_page_url":"https://network.satnogs.org/observations/"+oid+"/"}
    obs_summary.append(out)
    for field,api_v,client_v in [("latitude",obj.get("station_lat"),cm.get("latitude")),
                                 ("longitude",obj.get("station_lng"),cm.get("longitude")),
                                 ("elevation_m",obj.get("station_alt"),cm.get("elevation"))]:
        if api_v!=client_v: site_conflicts.append({"observation_id":oid,"station_id":obj["ground_station"],"field":field,
               "observation_field":api_v,"embedded_client_metadata":client_v,
               "action":"Preserve both; no silent replacement. Assess geometry sensitivity and confirm semantics if material."})
    for label,url in [("waterfall",obj.get("waterfall")),("archived_audio",obj.get("archive_url"))]:
        artifact_links.append({"observation_id":oid,"kind":label,"url":url or "","retrieval_status":"LINK_RETRIEVED_FROM_OBSERVATION; bytes not downloaded"})
    for demod in obj.get("demoddata",[]):
        artifact_links.append({"observation_id":oid,"kind":"demodulated_payload","url":demod["payload_demod"],"retrieval_status":"LINK_RETRIEVED_FROM_OBSERVATION; bytes not downloaded"})
missing=[r for r in cross if r["match_status"]!="MATCHED_METADATA"]
counts=collections.defaultdict(lambda:{"selected_receptions":0,"selected_ace_rows":0,"matched_receptions":0,"returned_frames":0})
for r in cross:
    a=counts[r["observer_match_name"]];a["selected_receptions"]+=1;a["selected_ace_rows"]+=r["ace_row_count"]
    a["matched_receptions"]+=r["match_status"]=="MATCHED_METADATA"
for r in returned:counts[r["Observer/Station"]]["returned_frames"]+=1
summary={
 "archive_date":"2026-11-11","historical_date":"2022-01-28","original_ace_rows":len(qualified),
 "original_unique_selected_receptions":len(cross),"ace_rows_per_selected_reception":dict(collections.Counter(x["ace_row_count"] for x in cross)),
 "returned_distinct_frames":len(set(r["Frame ID"] for r in returned)),"returned_rows":len(returned),
 "matched_selected_receptions":len(matched_ids),"selected_receptions_not_in_returned_extract":len(missing),
 "matched_ace_rows":sum(r["ace_row_count"] for r in cross if r["match_status"]=="MATCHED_METADATA"),
 "returned_frames_outside_original_selection":len(returned)-len(matched_ids),
 "returned_start_utc":min(utc(r["Timestamp"]) for r in returned),
 "returned_end_utc":max(utc(r["Timestamp"]) for r in returned),
 "selected_start_utc":min(r["reception_utc"] for r in cross),"selected_end_utc":max(r["reception_utc"] for r in cross),
 "by_receiver":dict(counts),"unmatched_selected":missing,"observation_metadata_differences":site_conflicts,
 "integrity_errors":errors,
 "join_caution":"Metadata reconciliation; original archive payload hashes checked. New frame payload contents were not independently compared because the telemetry API returned 401.",
 "source_license":"CC BY-SA 4.0, per Alfredos Damkalis correspondence",
 "research_scope":"Successful historical reception evidence. Does not establish attempted transmissions, packet loss, effective throughput, continuous availability, or modeled edge-processing outcomes."
}
assert len(qualified)==100 and len(cross)==50 and len(returned)==100
assert len(set(x["ace_entity"] for x in qualified))==100
assert sum(r["ace_row_count"] for r in cross)==100
assert len(set(x["Frame ID"] for x in returned))==100
assert len({(x["source_route"],x["observer_match_name"],x["reception_utc"]) for x in cross})==50
assert all(x["ace_row_count"]==2 for x in cross)
assert len([x for x in cross if x["match_status"]=="MATCHED_METADATA"])==len(matched_ids)
for observation in obs_summary:
    selected=[x for x in cross if x["original_observation_id"]==observation["observation_id"]]
    assert all(int(x["original_station_id"])==observation["station_id"] for x in selected)
    assert all(observation["start_utc"]<=x["reception_utc"]<=observation["end_utc"] for x in selected)
assert not errors,errors
write_csv("Selected_50_Receptions_Crosswalk_2026-11-11.csv",cross)
write_csv("Returned_100_Frames_Reconciliation_2026-11-11.csv",all_returned)
write_csv("ACE_100_Row_Reception_Map_2026-11-11.csv",sorted(ace,key=lambda r:int(r["ace_entity"])))
write_csv("Unmatched_Selected_Receptions_2026-11-11.csv",missing,cols=list(cross[0]))
write_csv("Network_Observation_Summary_2026-11-11.csv",obs_summary)
write_csv("Network_Observation_Metadata_Differences_2026-11-11.csv",site_conflicts,cols=["observation_id","station_id","field","observation_field","embedded_client_metadata","action"])
write_csv("Network_Observation_Artifact_Links_2026-11-11.csv",artifact_links)
(BASE/"derived/Reconciliation_Summary_2026-11-11.json").write_text(json.dumps(summary,indent=2)+"\n")
print(json.dumps(summary,indent=2))

