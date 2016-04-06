local creator={}
local editor
local world

local getDist = function(x1,y1,x2,y2) return math.sqrt((x1-x2)^2+(y1-y2)^2) end
local getRot  = function (x1,y1,x2,y2) 
	if x1==x2 and y1==y2 then return 0 end 
	local angle=math.atan((x1-x2)/(y1-y2))
	if y1-y2<0 then angle=angle-math.pi end
	if angle>0 then angle=angle-2*math.pi end
	if angle==0 then return 0 end
	return -angle
end
local axisRot = function(x,y,rot) return math.cos(rot)*x-math.sin(rot)*y,math.cos(rot)*y+math.sin(rot)*x  end
local polygonTrans= function(x,y,rot,size,v)
	local tab={}
	for i=1,#v/2 do
		tab[2*i-1],tab[2*i]=axisRot(v[2*i-1],v[2*i],rot)
		tab[2*i-1]=tab[2*i-1]*size+x
		tab[2*i]=tab[2*i]*size+y
	end
	return tab
end
local clamp= function (a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end


function creator:update()
	self:getPoints()
	self:getVerts()
	self:freeDraw()
end

function creator:new(cType)
	editor:cancel()
	editor.state="Create Mode"; 
	self.createTag=cType
	if cType=="circle" or cType=="box" or cType=="line" then
		self.needPoints=true
	elseif cType=="freeline" then
		self.needLines=true
	else
		self.needVerts=true
	end

end

function creator:draw()
	love.graphics.setColor(255, 255, 255, 255)
	if self.createTag then
		love.graphics.print("creating "..self.createTag, editor.mouseX+5,editor.mouseY+5,0,2,2)
	end

	if self.createOX then
		if self.createTag=="circle" then
			love.graphics.circle("line", self.createOX, self.createOY, self.createR)
			love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
		elseif self.createTag=="box" then
			love.graphics.polygon("line",
				self.createOX,self.createOY,
				self.createOX,self.createTY,
				self.createTX,self.createTY,
				self.createTX,self.createOY)
		elseif self.createTag=="line" then
			love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
		elseif self.createTag=="edge" or self.createTag=="freeline" then
			if not self.createVerts then return end
			for i=1,#self.createVerts-3,2 do
				love.graphics.line(self.createVerts[i],self.createVerts[i+1],self.createVerts[i+2],self.createVerts[i+3])
			end
			love.graphics.line(self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts],self.createTX,self.createTY)

		elseif self.createTag=="polygon" then
			if not self.createVerts then return end
			local count=#self.createVerts
			if count==0 then
				love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
			elseif count==2 then
				love.graphics.line(self.createOX,self.createOY,self.createVerts[1],self.createVerts[2])
				love.graphics.line(self.createVerts[1],self.createVerts[2],self.createTX,self.createTY)
				love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
			else
				
				love.graphics.line(self.createOX,self.createOY,self.createVerts[1],self.createVerts[2])
				for i=1,count-3,2 do
					love.graphics.line(self.createVerts[i],self.createVerts[i+1],self.createVerts[i+2],self.createVerts[i+3])
				end
				love.graphics.line(self.createVerts[count-1],self.createVerts[count],self.createTX,self.createTY)
				love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
			end
		end
	end

end




function creator:getPoints()
	if not self.needPoints then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createR=0
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		self.createR = getDist(self.createOX,self.createOY,self.createTX,self.createTY)
	elseif self.createOX and not love.mouse.isDown(1) then
		
		self:create()
	end
end

function creator:getVerts()
	if not self.needVerts then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		if love.mouse.isDown(2) and not self.rIsDown then
			self.rIsDown=true
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		elseif not love.mouse.isDown(2) then
			self.rIsDown=false
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
	end
end

function creator:freeDraw()
	if not self.needLines then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		local dist=getDist(self.createTX,self.createTY,self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts])
		if dist>3 then
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
	end


end


function creator:circle()
	editor.action="create circle"
	local body = love.physics.newBody(world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newCircleShape(self.createR)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body}
end

function creator:box()
	editor.action="create box"
	local body = love.physics.newBody(self.world, (self.createOX+self.createTX)/2, 
		(self.createTY+self.createOY)/2,"dynamic")
	local shape = love.physics.newRectangleShape(math.abs(self.createOX-self.createTX),math.abs(self.createTY-self.createOY))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body}
end

function creator:line()
	editor.action="create line"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newEdgeShape(0,0,self.createTX-self.createOX,self.createTY-self.createOY)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	sensor = love.physics.newFixture(body, shape)
	sensor:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function creator:edge()
	if #self.createVerts<6 then return end
	editor.action="create edge"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function creator:freeline()
	if #self.createVerts<6 then return end
	editor.action="create freeline"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end




function creator:polygon()
	if not self.createVerts then return end
	if #self.createVerts<6 then return end
	if #self.createVerts>16 then
		for i=16,#self.createVerts do
			self.createVerts[i]=nil
		end
	end
	editor.action="create polygon"	
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newPolygonShape(polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	local x,y=body:getWorldPoint(fixture:getMassData( ))
	body:destroy()
	local body = love.physics.newBody(self.world, x, y,"dynamic")
	local shape = love.physics.newPolygonShape(polygonTrans(-x, -y,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function creator:getBodies()
	local selection=editor.selector.selection
	if not selection then return end
	local body1,body2=selection[1],selection[2]
	if body1 and body2 then 
		return body1,body2 
	end
end

function creator:rope()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create rope joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint=love.physics.newRopeJoint(body1, body2, x1, y1, x2, y2, getDist(x1, y1, x2, y2), false)
	return joint
end

function creator:distance()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create distance joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, false)
	joint:setFrequency(10)
end

function creator:weld()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create weld joint"
	local x1,y1 = body1:getPosition()
	local joint = love.physics.newWeldJoint(body1, body2, x1, y1, false)
	joint:setFrequency(10)
end

function creator:prismatic()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create prismatic joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newPrismaticJoint(body1, body2, x2, y2, math.sin(angle), -math.cos(angle), false)
	--joint:setLimits(-90,50)
end

function creator:revolute()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create revolute joint"
	local x,y = body2:getPosition()
	local joint = love.physics.newRevoluteJoint(body1, body2, x, y, false)
end

function creator:pully()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create pully joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newPulleyJoint(body1, body2, x1, y1-200, x2, y2-200, x1, y1, x2, y2, 1, false)
end

function creator:wheel()
	local body2,body1=self:getBodies()
	if not body1 then return end
	editor.action="create wheel joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newWheelJoint(body2, body1, x1, y1, math.sin(angle), -math.cos(angle), false)
end


function creator:setMaterial(fixture,m_type)
	--editor.action="set material"..m_type
	if m_type=="wood" then
		fixture:setDensity(1)
		fixture:setFriction(1)
		fixture:setRestitution(0.2)
	elseif m_type=="rock" then
	end
end

function creator:cancel()
	self.createOX=nil
	self.createOY=nil
	self.createTX=nil
	self.createTY=nil
	self.needLines=false
	self.needPoints=false
	self.needVerts=false
	self.createTag=nil
	editor.state="Edit Mode"
end


function creator:create()
	if not self.createTag then return end
	if self.createOX==self.createTX and self.createOY==self.createTY then
		--do nothing?
	else
		self[self.createTag](self)
	end
	
	--[[
	for i,v in ipairs(self.createList) do
		if v~=self then
			v.toggle=false
		end
		
	end]]
	self.createOX=nil
	self.createOY=nil
	self.createTX=nil
	self.createTY=nil
	self.needLines=false
	self.needPoints=false
	self.needVerts=false
	self.createTag=nil
	editor.state="Edit Mode"
end

return function(parent) 
	editor=parent
	world=parent.world
	creator.world=world
	return creator 
end