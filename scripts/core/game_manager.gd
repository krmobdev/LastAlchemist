class_name GameManager
extends Node

var gold: int = 100
var reputation: int = 0
var day: int = 1

func reset_game() -> void:
    gold = 100
    reputation = 0
    day = 1
