class_name MailMessage
extends RefCounted
## A system mail with an optional claimable attachment.

var id: StringName
var sender: String = "System"
var subject: String = ""
var body: String = ""
var attachment: Reward = Reward.new()
var claimed: bool = false
var read: bool = false


static func make(p_id: StringName, p_subject: String, p_body: String, p_attachment: Reward) -> MailMessage:
	var mail := MailMessage.new()
	mail.id = p_id
	mail.subject = p_subject
	mail.body = p_body
	mail.attachment = p_attachment
	return mail


func has_unclaimed_attachment() -> bool:
	return not claimed and not attachment.is_empty()


func to_dict() -> Dictionary:
	return {
		"id": String(id), "sender": sender, "subject": subject, "body": body,
		"attachment": attachment.to_dict(), "claimed": claimed, "read": read,
	}


static func from_dict(data: Dictionary) -> MailMessage:
	var mail := MailMessage.make(DataReader.get_string_name(data, "id"), DataReader.get_string(data, "subject"), DataReader.get_string(data, "body"), Reward.from_dict(DataReader.get_dict(data, "attachment")))
	mail.sender = DataReader.get_string(data, "sender", "System")
	mail.claimed = DataReader.get_bool(data, "claimed")
	mail.read = DataReader.get_bool(data, "read")
	return mail
