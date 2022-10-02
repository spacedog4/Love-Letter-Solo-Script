function onLoad(save_state)
    self.interactable = false
end

function onCollisionEnter(info)
	Global.call('collisionOnTable', {info})
end