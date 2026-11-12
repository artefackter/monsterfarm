-- Daily quests. Each player gets one quest from each slot per UTC day: easy, middling, tough.
-- Goal and reward are fixed when picked, so earning more during the day never moves the goalposts.
-- Needs names a context flag from QuestService: a quest the player cannot do today is never offered.
return {
 DaySeconds=86400,
 Slots={{"dig","road","time"},{"earn","dawn","upgrade"},{"kill","rare","hatch"}},
 Rewards={{Seconds=60,Min=150},{Seconds=180,Min=400},{Seconds=300,Min=800}}, -- seconds of farm income, per slot
 RewardMax=5000000,
 HatchMinIncome=10,
 Quests={
  dig={Event="dig",Goal=3},
  plant={Event="plant",Goal=3},
  road={Event="road",Goal=3},
  time={Event="time",Goal=600,Display=60}, -- counted in seconds, shown in minutes
  earn={Event="earn",IncomeSeconds=300,GoalMin=500,GoalMax=50000000},
  dawn={Event="dawn",Goal=1},
  upgrade={Event="upgrade",Goal=1,Needs="canUpgrade"},
  kill={Event="kill",Goal=6,Needs="hasField"},
  rare={Event="rare",Goal=1},
  hatch={Event="hatch",Goal=1,Needs="canHatch"},
 },
 -- All three done: a grave voucher that stays worth having as the farm grows.
 Bonus={{MinIncome=0,Grave="Stone",Count=2},{MinIncome=60,Grave="Marble",Count=1},{MinIncome=1500,Grave="Golden",Count=1}},
}
