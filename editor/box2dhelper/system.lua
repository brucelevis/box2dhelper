local system={}
local helper
system.todo={}
system.delay={}
function system.addDelay(func,delay,...)
	table.insert(system.delay, {func,os.time()+delay,...})
end

function system.updateDelay()
	for i=#system.delay,1,-1 do
		local tab=system.delay[i]
		local func=tab[1]
		local expect=tab[2]
		if os.time()>=expect then
			table.remove(tab, 1)
			table.remove(tab, 1)
			func(unpack(tab))
			table.remove(system.delay, i)
		end
	end
end

function system.updateTodo()
	for i,v in ipairs(system.todo) do
		local func=v[1]
		table.remove(v,1)
		func(unpack(v))
	end
	system.todo={}
end


function system.update(...)
	local data={...}
	local world=data[1]
	if world==helper.world then
		helper.reactMode.update()
		system.updateTodo()
		system.updateDelay()
	end
	
	helper.drawMode.draw(...)
end




return function(parent) helper=parent;helper.system=system end