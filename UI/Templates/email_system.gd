extends Control

var emails = [
	{
		"From" : "Boss",
		"Subject" : "Coffee Run",
		"Content" : 
		r"""You should not be able to read this."""
	},
	{
		"From" : "Boss",
		"Subject" : "Re: Coffee Run",
		"Content" : 
		r"""You should not be able to read this."""
	},
	{
		"From" : "Boss",
		"Subject" : "Coffee?!!?!?",
		"Content" : 
		r"""You should not be able to read this."""
	},
	{
		"From" : "Boss",
		"Subject" : "PROMOTION",
		"Content" : 
		r"""Dear Employee,
		Good news you're promoted! Bad news its a punishment. You've forgotten to bring in the coffee too many times so you'll be running Conscious.net this meeting as a backup. Here's a tutorial to show you the ropes.""",
		"Type" : "Tutorial"
	},
	{
		"From" : "Boss",
		"Subject" : "Level 1",
		"Content" : 
		r"""Dear Employee,
		Trainings over! Here's your first job. Don't dissapoint me.""",
		"Type" : "Level",
		"LevelID" : 0
	},
	{
		"From" : "Card Download",
		"Subject" : "Add a card to your deck!",
		"Content" : 
		r"""Click one of the cards below to add it to your deck! Or click the "X" to skip!""",
		"Type" : "AddCard",
	},
	{
		"From" : "Card Removal",
		"Subject" : "Remove a card from your deck!",
		"Content" : 
		r"""Click one of the cards in your STORAGE, then click the "X" to throw it away permanently. Don't want to remove anything. You can click on the card in the email to select nothing and click the "X" to skip. """,
		"Type" : "RemoveCard",
	},
	{
		"From" : "Boss",
		"Subject" : "Level 2",
		"Content" : 
		r"""Dear Employee,
		Gotten used to your new job yet? Great! Here's your next task.""",
		"Type" : "Level",
		"LevelID" : 1
	},
	{
		"From" : "Card Download",
		"Subject" : "Add a card to your deck!",
		"Content" : 
		r"""Pick a card. Any card!""",
		"Type" : "AddCard",
	},
	{
		"From" : "Card Removal",
		"Subject" : "Remove a card from your deck!",
		"Content" : 
		r"""Leave a card. Any card!""",
		"Type" : "RemoveCard",
	},
	{
		"From" : "Boss",
		"Subject" : "Level 3",
		"Content" : 
		r"""Dear Employee,
		Hey nice work with that last job. Your reward? More work! Get it done.""",
		"Type" : "Level",
		"LevelID" : 2
	},
	{
		"From" : "Card Download",
		"Subject" : "Add a card to your deck!",
		"Content" : 
		r"""Pick a card. Any card!""",
		"Type" : "AddCard",
	},
	{
		"From" : "Card Removal",
		"Subject" : "Remove a card from your deck!",
		"Content" : 
		r"""Leave a card. Any card!""",
		"Type" : "RemoveCard",
	},
	{
		"From" : "Boss",
		"Subject" : "Level 4",
		"Content" : 
		r"""Dear Employee,
		You're actually doing better than I expected. Guess I should give you harder jobs then, huh?""",
		"Type" : "Level",
		"LevelID" : 3
	},
	{
		"From" : "Card Download",
		"Subject" : "Add a card to your deck!",
		"Content" : 
		r"""Pick a card. Any card!""",
		"Type" : "AddCard",
	},
	{
		"From" : "Card Removal",
		"Subject" : "Remove a card from your deck!",
		"Content" : 
		r"""Leave a card. Any card!""",
		"Type" : "RemoveCard",
	},
	{
		"From" : "Boss",
		"Subject" : "Level 5",
		"Content" : 
		r"""Dear Employee,
		Last job for the day newbie. This one's real important. Don't. Mess. It. Up.""",
		"Type" : "Level",
		"LevelID" : 4
	},
	{
		"From" : "Boss",
		"Subject" : "Good Job",
		"Content" : 
		r"""Dear Employee,
		Nice work with the Conscious.net today! I'll be expecting great things from you in the future.""",
		"Type" : "Info"
	}
]

var email_button_container:
	get:
		var node = get_node("VBoxContainer")
		if !node:
			print("Attempted to access EmailButtonContainer, but could not find it")
		return node 

var email_content:
	get:
		var node = get_node("EmailContent")
		if !node:
			print("Attempted to access EmailContent, but could not find it")
		return node 

const email_button = preload("res://UI/email_button.tscn")

var email_id = 0

var in_remove = false
var discard_card = -1

func _ready():
	post_next_email()
	post_next_email()
	post_next_email()
	post_next_email()

func post_next_email():
	if email_id >= emails.size():
		return
	
	var curr_email = emails[email_id]
	
	var child_count = email_button_container.get_child_count()
	if child_count > 0:
		var prev_button = email_button_container.get_child(child_count - 1)
		prev_button.disabled = true
		prev_button.focus_mode = Control.FOCUS_NONE
	if child_count >= 4:
		email_button_container.get_child(0).queue_free()
	
	var email_button_instance = email_button.instantiate()
	email_button_container.add_child(email_button_instance)
	email_button_instance.get_node("FromLabel").text = curr_email["From"]
	email_button_instance.get_node("SubjectLabel").text = curr_email["Subject"]
	email_button_instance.pressed.connect(open_email.bind(email_id))
	
	email_id += 1

var last_open_email = -1

func open_email(id):
	Global.audio_mouse.play()
	if last_open_email == id:
		return
	last_open_email = id
	var email = emails[id]
	
	get_node("InfoInput").text = email["From"] + "\nYou\n\n" + email["Subject"]
	email_content.get_node("Label").text = email["Content"]
	var email_container = email_content.get_node("EmailContainer")
	
	disconnect_confirm()
	
	for button in email_container.get_children():
		button.queue_free()
	if !email.has("Type"):
		return
	match email["Type"]:
		
		"Info":
			email_content.get_node("ConfirmButton").visible = false
		
		"Tutorial":
			email_content.get_node("ConfirmButton").visible = false
			var button_instance = Global.card_button.instantiate()
			email_container.add_child(button_instance)
			button_instance.icon = load("res://UI/Icons/Card_Heal.png")
			button_instance.get_node("CardName").text = "Tutorial.exe"
			button_instance.pressed.connect(
				func():
					Global.audio_mouse.play()
					button_instance.disabled = true
					Global.start_tutorial()
			)
			
		"Level":
			email_content.get_node("ConfirmButton").visible = false
			var level = Global.levels[email["LevelID"]]
			var button_instance = Global.card_button.instantiate()
			email_container.add_child(button_instance)
			button_instance.icon = load(level["Icon"])
			button_instance.get_node("CardName").text = level["Name"]
			button_instance.pressed.connect(
				func():
					Global.audio_mouse.play()
					button_instance.disabled = true
					Global.start_level(email["LevelID"])
			)
		
		"AddCard":
			var confirm_button = email_content.get_node("ConfirmButton")
			confirm_button.visible = true
			confirm_button.disabled = false
			confirm_button.pressed.connect(
				func():
					confirm_button.disabled = true
					Global.audio_mouse.play()
					for button in email_container.get_children():
						button.disabled = true
					post_next_email(),
					CONNECT_ONE_SHOT
			)
			for i in range(3):
				var card = Global.gen_card()
				var button_instance = Global.card_button.instantiate()
				email_container.add_child(button_instance)
				button_instance.icon = card.icon
				button_instance.get_node("CardName").text = card.name
				button_instance.get_node("APLabel").text = "%d Kb" % card.cost
				button_instance.tooltip_text = card.desc
				button_instance.pressed.connect(
					func():
						confirm_button.disabled = true
						Global.audio_mouse.play()
						Global.add_card_to_deck(card)
						for button in email_container.get_children():
							button.disabled = true
						post_next_email(),
				)
		
		"RemoveCard":
			var confirm_button = email_content.get_node("ConfirmButton")
			confirm_button.visible = true
			confirm_button.disabled = false
			confirm_button.pressed.connect(
				func():
					confirm_button.disabled = true
					Global.audio_mouse.play()
					for button in email_container.get_children():
						button.disabled = true
					if discard_card != -1:
						Global.remove_card_from_deck(discard_card)
					post_next_email(),
					CONNECT_ONE_SHOT
			)
			in_remove = true
			var button_instance = Global.card_button.instantiate()
			email_container.add_child(button_instance)
			button_instance.icon = null
			button_instance.get_node("CardName").text = ""
			button_instance.get_node("APLabel").text = ""
			discard_card = -1
			button_instance.pressed.connect(
				func():
					Global.audio_mouse.play()
					button_instance.icon = null
					button_instance.get_node("CardName").text = ""
					button_instance.get_node("APLabel").text = ""
					discard_card = -1
			)

func try_deck_discard(deck_id):
	if !in_remove:
		return
	var card = Global.deck[deck_id]
	var card_button = email_content.get_node("EmailContainer").get_child(0)
	card_button.icon = card.icon
	card_button.get_node("CardName").text = card.name
	card_button.get_node("APLabel").text = "%d Kb" % card.cost
	discard_card = deck_id

func disconnect_confirm():
	var confirm_button = email_content.get_node("ConfirmButton")
	for connection in confirm_button.pressed.get_connections():
		confirm_button.pressed.disconnect(connection.callable)
