class_name QuestDef
extends Resource
## Editable quest definition. Objectives target stable_id (NPC/object), never raw coordinates.

@export var id: String = ""
@export var title: String = ""
@export var summary: String = ""
@export var chapter: int = 1
## giver / turn-in NPC stable_id
@export var giver_stable_id: String = ""
@export var turnin_stable_id: String = ""
@export var next_quest_id: String = ""
@export var objectives: Array[Dictionary] = []
## example objective: {"type":"talk","stable_id":"npc_plazaelder","count":1,"text":"Поговорить со Старейшиной"}
## {"type":"kill","stable_id":"mob_shardling","count":3,"text":"Победить осколочников"}
## {"type":"goto","stable_id":"portal_ashen_gate","count":1,"text":"Дойти до портала"}
@export var reward_xp: int = 50
@export var reward_note: String = ""
