-- Friend invites. Roblox fills ReferredByPlayerId for every kind of invite. The friend gets a welcome grave at once;
-- the inviter is paid after the friend has really played, through a store because they may be on another server.
local DSS=game:GetService("DataStoreService");local Players=game:GetService("Players")
local RS=game.ReplicatedStorage
local C=require(RS.Shared.Config.SocialConfig).Referral
local D=require(script.Parent.DataService)
local R={Crediting={},Polling={},LastPoll={}}
local store=not D.Memory and DSS:GetDataStore(C.Store)
local memory={} -- Studio stand-in with the same "nil cancels the write" rule
R.Read=function(key) if store then return store:GetAsync(key) end return memory[key] end
R.Update=function(key,fn)
 if store then return store:UpdateAsync(key,fn) end
 local v=fn(memory[key]);if v~=nil then memory[key]=v end;return memory[key]
end
local function notice(p,key,args) RS.Remotes.Notice:FireClient(p,key,args) end
local function voucher(d,prize,times) d.vouchers[prize.Grave]=(d.vouchers[prize.Grave] or 0)+prize.Count*times end
-- A friend counts once, however many times they rejoin, and an inviter is paid at most Cap times ever.
function R.Credit(inviter,friend)
 return R.Update("inviter_"..inviter,function(old)
  old=old or {pending=0,total=0,friends={}}
  if old.friends[tostring(friend)] or old.total>=C.Cap then return nil end
  old.friends[tostring(friend)]=true;old.total+=1;old.pending+=1;return old
 end)
end
-- Takes everything pending in one transaction, so two servers can never pay the same friend twice.
function R.Poll(p)
 if R.Polling[p] or not D.Profiles[p] then return end
 R.Polling[p]=true;R.LastPoll[p]=os.clock()
 local key="inviter_"..p.UserId;local taken=0
 local ok,err=pcall(function()
  local now=R.Read(key);if not now or (now.pending or 0)<=0 then return end
  R.Update(key,function(old)
   taken=0;if not old or (old.pending or 0)<=0 then return nil end
   taken=old.pending;old.pending=0;return old
  end)
 end)
 R.Polling[p]=nil
 if not ok then warn("Referral poll failed",err);return end
 if taken<=0 then return end
 local d=D.Profiles[p]
 if not d then -- left while the transaction ran: put the reward back for their next visit
  pcall(R.Update,key,function(old) if old then old.pending=(old.pending or 0)+taken end;return old end);return
 end
 voucher(d,C.Reward,taken);notice(p,"inviteReward",{n=taken})
end
-- Only a brand new player counts: an old player clicking a link pays nobody.
function R.Apply(p,d,inviter)
 if type(inviter)~="number" or inviter<=0 or inviter==p.UserId or d.referredBy or (d.playTime or 0)>C.NewProfileSeconds then return false end
 d.referredBy=inviter;voucher(d,C.Welcome,1);notice(p,"inviteWelcome");return true
end
function R.Join(p,d)
 local ok,data=pcall(function() return p:GetJoinData() end)
 if ok and data then R.Apply(p,d,data.ReferredByPlayerId) end
 task.spawn(R.Poll,p)
end
function R.Tick(p,d)
 if d.referredBy and not d.referralPaid and (d.playTime or 0)>=C.PaySeconds and not R.Crediting[p] then
  R.Crediting[p]=true
  task.spawn(function()
   local ok,err=pcall(R.Credit,d.referredBy,p.UserId)
   if ok then
    d.referralPaid=true
    local inviter=Players:GetPlayerByUserId(d.referredBy);if inviter then R.Poll(inviter) end
   else warn("Referral credit failed",err);task.wait(C.RetryAfter) end
   R.Crediting[p]=nil
  end)
 end
 if os.clock()-(R.LastPoll[p] or 0)>=C.Poll then task.spawn(R.Poll,p) end
end
function R.Forget(p) R.Crediting[p]=nil;R.Polling[p]=nil;R.LastPoll[p]=nil end
return R
