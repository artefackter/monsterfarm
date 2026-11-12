-- Top farmers board, champion statue and friend invites.
return {
 Board={
  Store="GrowAMonster_IncomeBoard_v1", -- OrderedDataStore: UserId -> best income per second ever reached
  Fetch=50,WorldRows=10,
  FirstRefresh=5,Refresh=120,
  ProfileReread=600, -- how long an offline champion's best zombie is trusted before reading it again
  ChampionCandidates=3, -- if the #1 farmer has sold every zombie, the statue goes to the next one
  At=Vector3.new(-49,0,-12),SignScale=Vector3.new(4,5,1.4),FaceAt=Vector3.new(0,0,0),
 },
 Statue={At=Vector3.new(-49,0,12),FaceAt=Vector3.new(0,0,0),Scale=2.2,Gold="FFC62E",GoldDark="B97400"},
 Referral={
  Store="GrowAMonsterReferrals_v1", -- inviter_<UserId> -> {pending,total,friends}; the inviter may be on another server
  NewProfileSeconds=60, -- only a brand new player counts as invited
  PaySeconds=300, -- the inviter is paid once the friend has really played
  Poll=180,RetryAfter=60,Cap=10,
  Welcome={Grave="Stone",Count=1},Reward={Grave="Marble",Count=1},
 },
}
