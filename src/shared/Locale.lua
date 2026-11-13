local L={}
L.Rows={
SirenHead={"Siren Head","Сиреноголовый"},BuckshotDealer={"Dealer","Дилер"},

M249={"Pulik (M249)","Пулик"},Double={"Double barrel","Двушка"},Pump={"Pump shotgun","Помп"},MP5={"MP5","МП Пятка"},
weaponSkins={"Weapon skins","Скины оружия"},skinDefault={"Original","Оригинал"},skinSelect={"Apply skin","Надеть скин"},skinSelected={"Selected","Выбран"},skinOwnedHint={"AK finishes are available when you own the weapon. They change appearance only.","Скины Калаша доступны после покупки оружия. Они меняют только внешний вид."},backWeapons={"← Weapons","← Оружие"},
Asiimov={"Asiimov","Asiimov"},GoldenDragon={"Golden Dragon","Golden Dragon"},Cyberpunk={"Cyberpunk","Cyberpunk"},
RingMawFarmer={"RingMaw Farmer","Кольцевик Фермер"},RingMawPunk={"RingMaw Punk","Кольцевик Нефор"},RingMawAssassin={"RingMaw Assassin","Кольцевик Убийца"},CaveDwellerFarmer={"CaveDweller Farmer","Пещерник Фермер"},CaveDwellerPunk={"CaveDweller Punk","Пещерник Нефор"},CaveDwellerAssassin={"CaveDweller Assassin","Пещерник Убийца"},

placeWorker={"Pen: this zombie will earn Zombucks.","Загон: зомби будет приносить зомбуксы."},
placeDefender={"Yard: this zombie will defend with a weapon.","Двор: зомби будет защищать участок с оружием."},
placeGuardsFull={"All defender slots are taken. Upgrade on the board.","Все места защитников заняты. Купи место на табличке."},
placeCemetery={"Place graves anywhere in the cemetery, clear of the crypt.","Ставь могилы в свободном месте кладбища, вне склепа."},
hubMergeHint={"3 matching → 1 stronger","3 одинаковых → 1 сильнее"},
info={"Useful information","Полезная информация"},
hubInfoBoard={"Tips, mechanics\nand daily rewards\n\nStep into the circle","Советы, механики\nи ежедневные награды\n\nВстань в круг"},
hubInfoIntro={"Choose a topic. The plaza shops and boards are always here when you need them.","Выбери тему. Лавки и доски на площади всегда рядом."},

Deagle={"Deagle","Дигл"},AK={"AK","Калаш"},M4={"M4","Эмка"},AWP={"AWP","АВП"},
equipmentShop={"EQUIPMENT","СНАРЯЖЕНИЕ"},stealGrave={"Steal grave","Украсть могилу"},
tutorialRoad={"③ Dig up a grave on the road","③ Выкопай могилу на дороге"},
tutorialPlant={"④ Carry it home, then tap a cemetery spot","④ Принеси могилу домой и выбери место на кладбище"},
selectGrave={"Select → tap the ground","Выбрать → нажать на землю"},
selectedGrave={"Selected: {grave}. Tap a free place in the cemetery.","Выбрана: {grave}. Выбери свободное место на кладбище."},
quest_road={"Bring graves from the road: {n}","Принеси могилы с дороги: {n}"},
zombieCard={"Zombie","Зомби"},
placeOutside={"Not there: put it inside your yard.","Сюда нельзя: ставь во дворе фермы."},
placeCrowded={"Too close to something else.","Слишком близко к другому."},
placeBad={"Can't put it there.","Сюда поставить нельзя."},
placeFar={"Come closer to put it there.","Подойди поближе."},
placeGravesFull={"No room for more graves: buy a place on the board.","Мест для могил нет: купи место на табличке."},
placeFieldFull={"No room for more zombies: buy a place on the board.","Мест для зомби нет: купи место на табличке."},
placeNoGrave={"Pick a grave first (slot 3).","Сначала выбери могилу (слот 3)."},
placeReturned={"The zombie went back to the crypt.","Зомби вернулся в склеп."},
placeHint={"Tap the ground to put it down","Нажми на землю, чтобы поставить"},
holdZombie={"Take","Взять"},
roadNight={"Night in the ruins: richer graves and double rewards, but the mutants are faster and bite harder!","Ночь в заброшках: могилы ценнее, награды вдвое, но мутанты быстрее и кусают больнее!"},
nightIn={"Night in {t}","Ночь через {t}"},
dayIn={"Day in {t}","День через {t}"},
roadBossFirst={"Defeat the Head Doctor first!","Сначала победи Главврача!"},
roadBossLock={"🔒 Defeat the Head Doctor","🔒 Победи Главврача"},
roadSale={"-90%","-90%"},
roadReception={"RECEPTION","РЕГИСТРАТУРА"},
roadChiefDoor={"HEAD DOCTOR","ГЛАВВРАЧ"},
hubWelcome={"GROW A ZOMBIE!","ВЫРАСТИ ЗОМБИ!"},
trap={"Trap","Капкан"},
trapFull={"Your trap bag is full.","Сумка капканов полна."},
dailyLater={"Come back on that day!","Приходи в этот день!"},
choose={"Choose","Выбрать"},
questNotYet={"Not done yet!","Ещё не выполнено!"},
dropZombie={"Back to crypt","В склеп"},
dropGrave={"Drop","Бросить"},
roadDropHere={"Drop the grave on the road or on a farm","Бросить могилу можно на дороге или на ферме"},
shopGraves={"Graves","Могилы"},
cheapGravesOnly={"Wood and stone here. Find rare graves on the road!","В лавке — дерево и камень. Редкие могилы ищи на дороге!"},
guideIntro={"Pick a lesson. Follow the glowing arrows to its location.","Выбери урок. Светящиеся стрелки покажут путь к нужному месту."},
guideShow={"Show the way","Показать путь"},guideStop={"Hide arrows","Скрыть стрелки"},
guideDigTitle={"1. Grow and dig","1. Вырасти и выкопай"},guideDig={"Place a grave anywhere in the cemetery, clear of the crypt. Wait for it to grow, then hold Dig beside it. Your zombie goes to the crypt.","Поставь могилу в свободном месте кладбища, вне склепа. Дождись готовности и удерживай «Выкопать» рядом с ней. Зомби попадёт в склеп."},
guideFieldTitle={"2. Earn Zombucks","2. Зарабатывай зомбуксы"},guideField={"Take a zombie from the crypt. Place it in the wooden pen to earn Zombucks, or outside the pen to defend your farm with a weapon.","Возьми зомби из склепа. В деревянном загоне он приносит зомбуксы, а вне загона защищает участок с оружием."},
guideShopTitle={"3. The shop","3. Лавка"},guideShop={"Visit the central shop to buy wood and stone graves, weapons, pets and traps. Choose a category on the left.","У лавки на площади покупай деревянные и каменные могилы, оружие, питомцев и капканы. Категории — слева."},
guideHomeTitle={"4. House and merging","4. Дом и слияние"},guideHome={"Merge three matching zombies at the table on the central plaza. Walk into your house freely; house upgrades unlock more farm slots.","Объединяй трёх одинаковых зомби у стола на центральной площади. В дом можно зайти пешком; улучшение дома открывает новые места на ферме."},
guideTrainTitle={"5. Run faster","5. Беги быстрее"},guideTrain={"Stand on your treadmill to increase your speed. Training works only while you are in the game. Use the upgrade board beside it.","Встань на беговую дорожку, чтобы повысить скорость. Тренировка идёт только в игре. Улучшай дорожку на табличке рядом."},
guideRoadTitle={"6. Graves on the road","6. Могилы на дороге"},guideRoad={"Hold Take beside a road grave, carry it back through the gate. Rare graves lie farther away. Dodge mutants and slime.","Удерживай «Забрать» у могилы на дороге и вернись через ворота. Редкие могилы — дальше. Обходи мутантов и слизь."},
guideCombatTitle={"7. Auto fire and weapons","7. Автострельба и оружие"},guideCombat={"A drawn weapon aims and fires at nearby visible mutants. Keep moving! Select slot 2 to draw it, or another slot to put it away. Reload with R; auto fire can be toggled in settings.","Достанное оружие само целится в ближайших видимых мутантов. Продолжай двигаться! Слот 2 — достать, другой слот — убрать. Перезарядка — R. Автострельба переключается в настройках."},
guideBatTitle={"8. Shovel and traps","8. Лопата и капканы"},guideBat={"On the road, swing your shovel with empty hands to knock back a player and interrupt digging. Select a trap in slot 3 and tap the ground to place it. A trapped carrier drops the grave for anyone to pick up.","На дороге удар лопатой без могилы в руках отталкивает игрока и сбивает выкапывание. Выбери капкан в слоте 3 и нажми на землю. Попавший в капкан роняет могилу — её может подобрать любой."},
guideNightTitle={"9. Night and pets","9. Ночь и питомцы"},guideNight={"At night, protect your farm from raiders and theft. Equip pets from the paw menu for bonuses. Check quests and daily rewards for extra Zombucks.","Ночью защищай ферму от налётчиков и краж. Экипируй питомцев в меню с лапкой ради бонусов. Задания и ежедневные награды дают зомбуксы."},

weaponHolster={"Holster","Убрать оружие"},weaponDraw={"Draw weapon","Достать оружие"},
batCarryDenied={"Put down the grave to use the bat.","С могилой в руках нельзя использовать биту."},
Spitter={"Spitter","Плевун"},Bubble={"Bubble","Пузырь"},Chief={"Chief Physician","Главврач"},
traps={"Brawler","Драчун"},guide={"How to play","Обучение"},
roadYard={"THE YARD","ДВОР"},roadMall={"SHOPPING MALL","ТОРГОВЫЙ ЦЕНТР"},roadFactory={"MUTAGEN FACTORY","ЗАВОД МУТАГЕНА"},roadClinic={"CLINIC","ПОЛИКЛИНИКА"},roadChief={"CHIEF PHYSICIAN","КАБИНЕТ ГЛАВВРАЧА"},
roadBat={"Bat","Бита"},
roadTrap={"Trap ×{n}","Капкан ×{n}"},
roadBatHint={"Free bat: interrupt a grave pickup on the road. Carried graves stay safe from bats.","Бита бесплатна: сбивает подбор на дороге, но не выбивает переносимую могилу."},
trapShop={"Trap · Stock {n}/{max}","Капкан · В запасе {n}/{max}"},
trapBuy={"Buy · {n} Zombucks","Купить · {n} зомбуксов"},
trapHint={"Place on the road. Traps catch other players, drop their grave and expire after 60s.","Ставится на дороге. Ловит других игроков, выбивает могилу. Исчезает через 60 с."},
trapBought={"Trap purchased! Use the trap button on the road.","Капкан куплен! Установи его кнопкой на дороге."},
trapPlaced={"Trap placed! Arms in a moment. Your own traps won't catch you.","Капкан установлен! Скоро взведётся. На свой капкан ты не попадёшь."},
trapCaughtDrop={"Caught! Your grave dropped — anyone can pick it up.","Капкан! Могила выпала — её может подобрать любой."},
roadDroppedObject={"Dropped: {grave} · Anyone can take it","Выпала: {grave} · Для всех"},
trapCaught={"Caught in a trap!","Ты попался в капкан!"},
roadDropped={"Grave dropped! Anyone can pick it up.","Могила выпала! Её может подобрать любой."},
roadPickupInterrupted={"Pickup interrupted! Hold again to pick it up.","Подбор сбит! Начни удержание заново."},
trapVisitShop={"Buy traps at the central shop.","Покупай капканы у лавки на площади."},
trapStockFull={"You already carry 10 traps.","В запасе уже 10 капканов."},
trapPlacedFull={"You already have 3 active traps.","На дороге уже стоят 3 твоих капкана."},
trapNoCoins={"Not enough Zombucks for a trap.","Не хватает зомбуксов на капкан."},
trapEmpty={"No traps left. Buy more at the shop.","Капканы закончились. Купи ещё в лавке."},
trapBadSpot={"Find clear ground away from the gate and other traps.","Нужно свободное место подальше от ворот и других капканов."},
roadGearDenied={"Use on the road with free hands.","Используется на дороге, когда руки свободны."},

signRoad={"ROAD TO THE RUINS","ДОРОГА В ЗАБРОШКИ"},
roadGrab={"Take it","Забрать"},
roadRare={"A grave has appeared on the road: {grave}!","На дороге появилась могила: {grave}!"},
roadDelivered={"Delivered! Planted at your farm: {grave}","Доставлено! На ферме посажена могила: {grave}"},
roadStored={"Delivered! No room at the farm, so it's in your inventory: {grave}","Доставлено! На ферме нет места, могила в инвентаре: {grave}"},
roadLost={"You lost the grave!","Могила потеряна!"},
roadFaint={"The Imps got you. Back to the gate!","Бесы тебя загрызли. Обратно к воротам!"},
roadFell={"Into the sea! Back to the gate.","Прямо в море! Обратно к воротам."},
roomTreadmill={"Treadmill","Беговая дорожка"},
treadmill={"Treadmill","Беговая дорожка"},
treadmillLine={"Speed {speed} · +{rate} a minute while you stand on it","Скорость {speed} · +{rate} в минуту, пока стоишь на ней"},
plant={"Plant","Посадить"},
house={"House","Дом"},
signHome={"HOME","ДОМ"},
roomMerge={"Merge table","Стол слияния"},
roomBoard={"House upgrades","Улучшения дома"},
roomCrypt={"Crypt","Склеп"},
roomExit={"Way out","Выход"},
roomSweet={"HOME SWEET GRAVE","ДОМ, МИЛЫЙ ГРОБ"},
houseEnter={"Go in","Войти"},
houseExit={"Go out","Выйти"},
house_merge={"Merge","Слияние"},
house_house={"Upgrades","Улучшения"},
house_crypt={"Crypt","Склеп"},
houseLevel={"House, level {n}","Дом, уровень {n}"},
houseNeed={"Needs house level {n}","Нужен дом уровня {n}"},
houseLimit={"Upgrade your house to level {n} first.","Сначала улучши дом до уровня {n}."},
houseMax={"The finest house on the island. Nowhere left to grow.","Лучший дом на острове. Расти больше некуда."},
houseGo={"Upgrade · 💰 {price} · {time}","Улучшить · 💰 {price} · {time}"},
houseBuilding={"Building… {time}","Стройка… {time}"},
houseDone={"Your house is now level {n}!","Дом вырос до уровня {n}!"},
houseVisit={"Go to my house","Пойти домой"},
houseLeave={"Leave the house","Выйти из дома"},
zoneMax={"Maximum","Максимум"},
timeMin={"{n} min","{n} мин"},
merge={"Merge","Слияние"},
mergeHint={"Three identical zombies become one with an extra star. The best mutation stays.","Три одинаковых зомби станут одним с новой звездой. Лучшая мутация сохранится."},
mergeGo={"Merge","Собрать"},
mergeNeedThree={"Put three identical zombies in the slots.","Поставь в слоты трёх одинаковых зомби."},
mergeNeed={"{n} more","Ещё {n}"},
mergePick={"Pick","Выбрать"},
mergeNone={"Nothing to merge yet. Dig up more zombies!","Пока нечего сливать. Выкапывай ещё зомби!"},
mergeDone={"Merged!","Слияние!"},
mergeClear={"Clear slots","Очистить слоты"},
mergeReady={"Ready to merge: {n}","Можно собрать: {n}"},
starRare={"{name} made a three-star {type}!","{name} собирает трёхзвёздного: {type}!"},
expand={"Expand","Расширить"},
inventory={"Inventory","Инвентарь"},
settings={"Settings","Настройки"},
language={"Language","Язык"},
language_auto={"Auto","Авто"},
language_en={"English","English"},
language_ru={"Русский","Русский"},
incomeShort={"+{n}/s","+{n}/с"},
inventoryWeapons={"Weapons","Оружие"},
inventoryGraves={"Select a grave, then tap a free grave spot on your farm.","Выбери могилу и нажми на свободное место на своём кладбище."},
inventoryNoGraves={"No free graves yet. Daily rewards and quests give them.","Бесплатных могил пока нет. Их дают награды и задания."},
inHand={"In hand","В руках"},
weaponAutoOn={"AUTO: ON","АВТООГОНЬ: ВКЛ"},
weaponAutoOff={"AUTO: OFF","АВТООГОНЬ: ВЫКЛ"},
quests={"Quests","Задания"},
top={"Top farmers","Топ фермеров"},
invite={"Invite","Позвать"},
perSecond={"/s","/с"},
quest_dig={"Dig up {n} zombies","Выкопай {n} зомби"},
quest_plant={"Plant graves: {n}","Посади могилы: {n}"},
quest_time={"Hang out on the farm for {n} minutes","Побудь на ферме {n} минут"},
quest_earn={"Earn Zombucks on the farm: {n}","Заработай на ферме зомбуксов: {n}"},
quest_dawn={"Stay up until dawn","Дождись рассвета"},
quest_upgrade={"Upgrade your farm","Улучши ферму"},
quest_kill={"Blast Imps: {n}","Отстрели бесов: {n}"},
quest_rare={"Dig up an Uncommon zombie or better","Выкопай необычного зомби или круче"},
quest_hatch={"Hatch a pet from a pumpkin","Вылупи питомца из тыквы"},
questDone={"Quest done: {name}!","Задание выполнено: {name}!"},
questBonus={"All three quests","Все три задания"},
questReset={"New quests in {h} h {m} min","Новые задания через {h} ч {m} мин"},
topYou={"You are #{n}","Ты на {n} месте"},
topNotYet={"Not on the board yet","Пока не в таблице"},
topPeak={"Your best: {n}/s","Твой рекорд: {n}/с"},
topEmpty={"Nobody here yet. Be the first!","Пока пусто. Будь первым!"},
boardTitle={"TOP FARMERS · COINS PER SECOND","ТОП ФЕРМЕРОВ · МОНЕТ В СЕКУНДУ"},
statueEmpty={"YOUR STATUE COULD BE HERE","ЗДЕСЬ МОГЛА БЫТЬ ВАША СТАТУЯ"},
statuePlaque={"Best zombie: {zombie}. Owner: {name}","Лучший зомби: {zombie}. Хозяин: {name}"},
inviteInfo={"Invite a friend who is new here. They get a Stone grave right away, and you get a Marble grave once they have played for 5 minutes.","Позови друга, который ещё не играл. Он сразу получит каменную могилу, а ты мраморную, когда он наиграет 5 минут."},
invitePrompt={"Invite friends and you both get a grave!","Позови друзей, и вы оба получите могилу!"},
inviteUnavailable={"Invites are not available right now.","Приглашения сейчас недоступны."},
inviteWelcome={"A friend invited you! A free Stone grave is waiting in the shop.","Тебя позвал друг! В лавке ждёт бесплатная каменная могила."},
inviteReward={"Your friend settled in! Marble graves in the shop: +{n}","Твой друг освоился! Мраморных могил в лавке: +{n}"},
Imp={"Imp","Бес"},
mutantWave={"Imps incoming!","Бесы идут!"},
mutantNewbie={"Ptooey! Your zombie tastes like broccoli. No Zombucks lost!","Тьфу, твой зомби пахнет брокколи! Зомбуксы целы."},
mutantStolen={"An Imp snatched {n} Zombucks! Your zombie needs a rest.","Бес стащил {n} зомбуксов! Зомби нужно прийти в себя."},
weapons={"Gunsmith","Оружейник"},
Pistol={"Pistol","Пистолет"},
Rifle={"Rifle","Автомат"},
Shotgun={"Shotgun","Дробовик"},
weaponFire={"FIRE","ОГОНЬ"},
weaponReload={"Reload [R]","Зарядить [R]"},
weaponReloading={"Reloading…","Перезарядка…"},
weaponDenied={"Cannot do that now. Check the gun, Zombucks and mutagen.","Сейчас нельзя. Проверь оружие, зомбуксы и мутаген."},
weaponOwned={"Select","Выбрать"},
weaponBuy={"Buy · {n}","Купить · {n}"},
weaponStats={"{damage} damage × {pellets} · {rate}/s · {range} studs","Урон {damage} × {pellets} · {rate}/с · {range} стад."},
weaponHint={"Blasters only hit Imps. Help any farm!","Бластеры бьют только Бесов. Помоги любой ферме!"},

 caught={"Caught by the guards!","Сторожа тебя поймали!"},
pumpkins={"Pet shop","Питомник"},
pets={"Pets","Питомцы"},
petShop={"Pet pumpkins","Тыквы питомцев"},
petEquip={"Equip","Надеть"},
petUnequip={"Unequip","Снять"},
petBest={"Equip best","Надеть лучших"},
petRelease={"Release for {n} Zombucks","Отпустить за {n} зомбуксов"},
petConfirm={"Confirm release?","Точно отпустить?"},
petSlots={"Equipped {n}/{max}","Надето {n}/{max}"},
petSlotBuy={"Extra slot: {n}","Ещё слот: {n}"},
petBonuses={"Pet bonuses","Бонусы питомцев"},
petLimit={"LIMIT","ЛИМИТ"},
petFull={"Pet inventory is full (30).","Инвентарь питомцев полон (30)."},
petNoCoins={"Not enough Zombucks.","Не хватает зомбуксов."},
petSlotsFull={"All pet slots are occupied.","Все слоты питомцев заняты."},
petUnequipFirst={"Unequip this pet first.","Сначала сними питомца."},
petNightOnly={"Available only at night.","Доступно только ночью."},
petShopDistance={"Visit the shop in the central plaza.","Подойди к магазину на площади."},
petBusy={"Finish your raid first.","Сначала заверши набег."},
petMaxSlots={"Maximum pet slots reached.","Уже открыты все слоты."},
petCryptFull={"Crypt full!","Склеп полон!"},
petStarter={"Farmer Cat is here! Open Pets → Equip.","Кот-фермер помогает тебе! Питомцы → Надеть."},
petDug={"Cat dug up {rarity} {type}!","Кот выкопал: {rarity} {type}!"},
petRare={"{name} hatched {rarity} {species}!","{name} вылупил: {rarity} {species}!"},
petAlarm={"A thief is on your farm!","На участке чужой игрок!"},
petHatch={"Hatch · {n} Zombucks","Вылупить · {n} зомбуксов"},
petOdds={"C/U/R/E/L: {n}%","О/Н/Р/Э/Л: {n}%"},
petEmpty={"Hatch a pumpkin or finish the tutorial for your first cat.","Вылупи тыкву или заверши обучение, чтобы получить кота."},
petNightIn={"Night in {n}s","До ночи: {n} с"},
petAbility_FarmerCat={"Digs a grave every {n}s","Выкапывает могилу раз в {n} с"},
petAbility_DiggerMole={"Grave speed +{n}%","Созревание +{n}%"},
petAbility_CoinHen={"Farmer income +{n}%","Доход фермеров +{n}%"},
petAbility_LuckyOwl={"Mutation chance ×{n}","Шанс мутации ×{n}"},
petAbility_GuardDog={"Catch chance +{n}%, alarm","Поимка +{n}%, тревога"},
petAbility_BanditBat={"Carry penalty −{n} pp","Штраф переноски −{n} п.п."},
petSummary={"Income +{income}% · speed {speed}% · catch {guard}% · luck ×{luck} · carry penalty {carry}% · cats {cats}","Доход +{income}% · созревание {speed}% · поимка {guard}% · удача ×{luck} · штраф {carry}% · котов {cats}"},
FarmerCat={"Farmer Cat","Кот-фермер"},
DiggerMole={"Digger Mole","Крот-копатель"},
CoinHen={"Coin Hen","Курица-несушка"},
LuckyOwl={"Lucky Owl","Сова-везунчик"},
GuardDog={"Guard Dog","Пёс-сторож"},
BanditBat={"Bandit Bat","Мышь-бандит"},
Pumpkin={"Pumpkin","Тыква"},
BigPumpkin={"Big Pumpkin","Большая тыква"},
GoldenPumpkin={"Golden Pumpkin","Золотая тыква"},
LunarPumpkin={"Lunar Pumpkin","Лунная тыква"},

 incomeStat={"Income/s","Доход/с"},
 grave_Wooden={"Wooden","Деревянная"},
 grave_Stone={"Stone","Каменная"},
 grave_Marble={"Marble","Мраморная"},
 grave_Golden={"Golden","Золотая"},
 grave_Lunar={"Lunar","Лунная"},
 move_Field={"Take","Взять"},
 move_Diggers={"To graveyard","На кладбище"},
 move_Guards={"To gates","На ворота"},
 move_Crypt={"To crypt","В склеп"},
 serverFull={"This server is full. Please join another server.","На сервере нет свободных мест. Зайди на другой сервер."},
 numberK={"{n}K","{n} тыс."},
 numberM={"{n}M","{n} млн"},
 numberB={"{n}B","{n} млрд"},
 shopPrice={"{price} Zombucks","Цена: {price}"},
 shopDetails={"{time}s · stock {stock}","{time} с · осталось: {stock}"},
 chanceLegend={"Common / Uncommon / Rare / Epic / Legendary / Mythic","Обычный / Необычный / Редкий / Эпический / Легендарный / Мифический"},

 signShop={"GRAVE SHOP","ЛАВКА МОГИЛ"},signFeed={"DO NOT FEED THE ZOMBIES. THEY MANAGE.","НЕ КОРМИТЬ ЗОМБИ. ОНИ САМИ."},signBio={"ORGANIC BRAINS. FREE RANGE.","БИО-МОЗГИ. ВЫРАЩЕНО БЕЗ ГОЛОВЫ."},signQuiet={"QUIET! SOME OF US ARE STILL DEAD.","ТИШЕ! НЕ ВСЕ ЕЩЁ ВСТАЛИ."},signOuthouse={"OCCUPIED SINCE 1784","ЗАНЯТО С 1784"},signCrypt={"PLEASE KNOCK","СТУЧАТЬ!"},signMat={"WELCOME! NO RETURNS","ДОБРО ПОЖАЛОВАТЬ! ВОЗВРАТА НЕТ"},signFountain={"SLIME FOUNTAIN. DO NOT DRINK. AGAIN.","ФОНТАН СЛИЗИ. НЕ ПИТЬ. СНОВА."},epitaph1={"HERE LIES STEVE. FOR NOW.","ТУТ ЛЕЖИТ ВАСЯ. ПОКА ЧТО."},epitaph2={"BACK IN 5 MINUTES","ВЕРНУСЬ ЧЕРЕЗ 5 МИНУТ"},epitaph3={"I TOLD YOU I WAS SICK","Я ЖЕ ГОВОРИЛ, ЧТО БОЛЕЮ"},epitaph4={"DO NOT WAKE BEFORE LUNCH","НЕ БУДИТЬ ДО ОБЕДА"},epitaph5={"GONE DIGGING","УШЁЛ КОПАТЬ"},epitaph6={"RENT DUE: NEVER","АРЕНДА: НИКОГДА"},epitaph7={"SPOT TAKEN","МЕСТО ЗАНЯТО"},epitaph8={"JUST RESTING MY EYES","ПРОСТО ПРИЛЁГ"},nice={"Nice!","Ура!"},reveal={"You dug up:","Ты выкопал:"},title={"DIG A ZOMBIE","ВЫКОПАЙ ЗОМБИ"},shop={"Equipment","Снаряжение"},crypt={"Crypt","Склеп"},dex={"Zombiedex","Зомбидекс"},rewards={"Daily rewards","Награды"},close={"Close","Закрыть"},dig={"Dig up!","Выкопай!"},steal={"Steal grave","Украсть могилу"},shoo={"Shoo!","Шугнуть!"},lock={"Lock gates","Запереть ворота"},Field={"Beds","Грядки"},Diggers={"Diggers","Копатели"},Guards={"Guards","Сторожа"},Crypt={"Crypt","Склеп"},Graves={"Graves","Могилы"},sell={"Sell","Продать"},claim={"Claim","Забрать"},buy={"Buy / plant","Купить / посадить"},upgrade={"Add space","Добавить место"},day={"☀️ Day","☀️ День"},night={"🌙 Night","🌙 Ночь"},coins={"Zombucks: {n}","Зомбуксы: {n}"},income={"Income: {n}/s","Доход: {n}/с"},offline={"While away: {n} Zombucks","Пока тебя не было: {n} зомбуксов"},refresh={"New stock in {n}s","Обновление через {n} с"},graveInfo={"{price} Zombucks · {time}s · stock {stock}","{price} зомбуксов · {time} с · осталось {stock}"},chances={"C/U/R/E/L/M: {n}%","О/Н/Р/Э/Л/М: {n}%"},ready={"Ready!","Созрела!"},waiting={"Growing: {n}s","Созреет через {n} с"},empty={"No zombies yet. Dig your first grave!","Пока пусто. Выкопай первую могилу!"},error={"Action unavailable. Check distance, Zombucks, space or protection.","Недоступно: проверь расстояние, зомбуксы, места и защиту."},ok={"Done!","Готово!"},rare={"{name} dug up {rarity} {type}!","{name} выкопал: {rarity} {type}!"},tutorialDig={"① Walk to your grave and hold E / tap Dig","① Подойди к могиле и удерживай «Выкопать»"},tutorialField={"② Take a zombie at the crypt and put it in your yard","② Возьми зомби в склепе и поставь во дворе"},tutorialShop={"③ Visit the central shop and buy Wooden","③ Купи деревянную могилу в магазине на площади"},tutorialDone={"Grow your collection. Protect it at night!","Собирай зомби и защищай их ночью!"},all={"All","Все"},None={"Normal","Обычный"},Golden={"Golden","Золотой"},Lunar={"Lunar","Лунный"},Rainbow={"Rainbow","Радужный"},Wooden={"Wooden","Деревянная"},Stone={"Stone","Каменная"},Marble={"Marble","Мраморная"},Common={"Common","Обычный"},Uncommon={"Uncommon","Необычный"},Rare={"Rare","Редкий"},Epic={"Epic","Эпический"},Legendary={"Legendary","Легендарный"},Mythic={"Mythic","Мифический"},Pajama={"Pajama","Соня"},Gardener={"Gardener","Садовник"},Postman={"Postman","Почтальон"},Skater={"Skater","Скейтер"},Pirate={"Pirate","Пират"},Cowboy={"Cowboy","Ковбой"},Knight={"Knight","Рыцарь"},DJ={"DJ","Диджей"},King={"King","Король"},Astronaut={"Astronaut","Космонавт"},Dragon={"Dragon","Дракон"},loadError={"Could not safely load your farm. Please rejoin.","Не удалось безопасно загрузить ферму. Перезайди."},savingError={"Farm save unavailable. Please rejoin later.","Сохранение недоступно. Зайди позже."},busy={"This farm is open on another server. Try again shortly.","Ферма открыта на другом сервере. Попробуй позже."},owner={"{name}'s farm","Ферма: {name}"},unclaimed={"Available farm","Свободный участок"},protection={"Newbie shield: {n}s","Защита новичка: {n} с"},daily={"Day {n}","День {n}"},voucher={"Vouchers: {n}","Могилы в запасе: {n}"},found={"Collection: {n}/44","Коллекция: {n}/44"}}
-- Locale is resolved per viewer; server-owned shared signs never choose one player's language.
-- Help cards, quest reminder, empty farms, the heap, weapon upgrades (2026-11-10)
L.Rows.nightDefendTitle={"Protect your farm","Защити ферму"}
L.Rows.nightDefendBody={"Monsters break gates and steal Zombucks.","Монстры ломают ворота и крадут зомбуксы."}
L.Rows.nightLockTitle={"Lock your gates","Закрой ворота"}
L.Rows.nightLockBody={"At night, players can steal your graves.","Ночью игроки могут украсть могилы."}
L.Rows.nightRuinsTitle={"Explore the ruins","Исследуй заброшки"}
L.Rows.nightRuinsBody={"Rewards ×2 and lunar graves. Stronger monsters.","Награды ×2 и лунные могилы. Монстры сильнее."}
L.Rows.nightUntilDawn={"Until dawn  {time}","До рассвета  {time}"}
L.Rows.nightUntilDusk={"Until night  {time}","До ночи  {time}"}
L.Rows.nightUnderstood={"Got it","Понятно"}
L.Rows.nightDontShowAgain={"Don't show again","Больше не показывать"}
L.Rows.ShowNightInfo={"Show night reminders","Показывать подсказку о ночи"}
L.Rows.nightCardTitle={"Night has come!","Наступила ночь!"}
L.Rows.nightCardDay={"What happens at night","Что бывает ночью"}
L.Rows.nightCard1={"Monsters raid the farm: they break the gate, then steal Zombucks. Shoot them and upgrade the fence!","Монстры идут на ферму: ломают ворота и крадут зомбуксы. Стреляй и улучшай забор!"}
L.Rows.nightCard2={"Players can steal your graves. Lock the gate!","Игроки могут украсть твои могилы. Закрой ворота!"}
L.Rows.nightCard3={"In the ruins: double rewards and lunar graves, angrier monsters","В заброшках: награды ×2 и лунные могилы, но монстры злее"}
L.Rows.questReady={"Quest done! Take the reward with the Quests button ({n})","Задание выполнено! Забери награду кнопкой «Задания» ({n})"}
L.Rows.inviteFriend={"Invite a friend","Позвать друга"}
L.Rows.emptyFarm={"Free farm","Свободная ферма"}
L.Rows.guardLabel={"Guard","Охранник"}
L.Rows.inviteUnavailable=L.Rows.inviteUnavailable or {"Invites are unavailable right now.","Приглашения сейчас недоступны."}
L.Rows.referenceQuest_road={"Bring graves\nfrom the road","Принеси могилы\nс дороги"}
L.Rows.referenceQuest_rare={"Dig up an Uncommon\nmonster or better","Выкопай необычного\nмонстра или круче"}
L.Rows.referenceGravePrize={"{name} grave","{name} могила"}
L.Rows.referenceClaimed={"Claimed","Получено"}
L.Rows.referenceAllQuests={"All quests","Все задания"}
L.Rows.referenceDailyRewards={"Daily rewards","Ежедневные награды"}
L.Rows.referenceSpecialReward={"Special reward","Особая награда"}
L.Rows.weaponWorkshop={"Weapon workshop","Мастерская оружия"}
L.Rows.weaponWorkshopHint={"Mutagen drops in the ruins.","Мутаген выпадает в заброшках."}
L.Rows.weaponUpgrade={"Weapon upgrades","Улучшение оружия"}
L.Rows.up_Damage={"Damage","Урон"}
L.Rows.up_FireRate={"Fire rate","Темп стрельбы"}
L.Rows.up_Magazine={"Magazine","Обойма"}
L.Rows.up_Crit={"Critical hit","Крит. урон"}
L.Rows.revealIncome={"Income","Доход"}
L.Rows.upInsufficient={"Not enough","Не хватает"}
L.Rows.upLocked={"Not earned","Не получено"}
L.Rows.upMax={"MAX","МАКС"}
L.Rows.upgradeTile={"Upgrade","Улучшить"}
L.Rows.mutagen={"Mutagen","Мутаген"}
L.Rows.mutagenDrop={"+{n} mutagen!","+{n} мутагена!"}
L.Rows.mutagenHint={"Mutagen drops from monsters in the ruins","Мутаген падает с монстров в заброшках"}
L.Rows.perSecond={"/s","/с"}
L.Rows.newbieBoost={"Newbie boost: income x{n}  {time}","Буст новичка: доход ×{n}  {time}"}
function L.normalize(locale)
 return type(locale)=="string" and string.lower(locale):sub(1,2)=="ru" and "ru" or "en"
end
function L.lang(player)
 -- A language the player picked in Settings beats everything; the server stores it as an attribute.
 local who=player or game:GetService("Players").LocalPlayer
 local chosen=who and who:GetAttribute("Language")
 if chosen=="en" or chosen=="ru" then return chosen end
 local preview=game:GetService("RunService"):IsStudio() and workspace:GetAttribute("DebugLocale")
 if type(preview)=="string" and preview~="" then return L.normalize(preview) end
 return L.normalize(player and player.LocaleId or game:GetService("LocalizationService").RobloxLocaleId)
end
function L.number(value,locale,decimals)
 local text=string.format("%."..tostring(decimals or 0).."f",value)
 if L.normalize(locale)=="ru" then text=text:gsub("%.",",") end
 return text
end
L.Rows.treadmillLine={'Speed: {speed} · +{rate} / step','Скорость: {speed} · +{rate} / шаг'}
L.Rows.roadBatHint={'Shovel: interrupt digging, knock down rivals on the road and hit mutants.','Лопата: срывай копание, выбивай могилы на дороге и бей мутантов.'}
L.Rows.trapHint={'Place on the road or your farm. Catches other players carrying graves.','Ставь на дороге или своей ферме. Ловит чужих игроков с могилами.'}
L.Rows.shovelStats={'Range {range} · Damage {damage}','Дальность {range} · Урон {damage}'}
L.Rows.dexReward={'Zombiedex reward','Награда Зомбидекса'}
L.Rows.slotWeapon={'Weapon','Оружие'};L.Rows.slotShovel={'Shovel','Лопата'};L.Rows.slowMode={'Slow mode','Медленный режим'};L.Rows.showRanges={'Show action ranges','Радиусы действий'};L.Rows.actionBlocked={'Action unavailable right now.','Сейчас действие недоступно.'}
L.Rows.roadBat={'Strike','Удар'}
for id,ru in {Rusty='Ржавая',Steel='Стальная',Combat='Боевая',Bone='Костяная',Golden='Золотая',Lunar='Лунная',Rainbow='Радужная'} do L.Rows['shovel_'..id]={id..' shovel',ru..' лопата'} end
L.Rows["home"]={"Home","Домой"}
L.Rows["homeUnavailable"]={"Home is unavailable right now.","Сейчас нельзя домой."}
L.Rows["homeRoad"]={"Leave the ruins road first.","Сначала выйди с дороги заброшек."}
L.Rows["homeCarry"]={"Deliver or drop the grave first.","Сначала доставь или урони могилу."}
L.Rows["homeDig"]={"Finish digging first.","Сначала закончи выкапывание."}
L.Rows["homeKO"]={"Wait until you get up.","Подожди, пока встанешь."}
L.Rows["homeTrap"]={"Wait for the trap to release you.","Подожди, пока отпустит капкан."}
L.Rows["homeCooldown"]={"Home will be ready in a few seconds.","Домой можно через несколько секунд."}
L.Rows["freeGift"]={"FREE!","БЕСПЛАТНО!"}
L.Rows["giftGroupRequired"]={"Join the community, then try again. If you just joined, rejoin the game.","Вступи в сообщество и попробуй снова. Если только что вступил — перезайди в игру."}
L.Rows["giftReward"]={"+10,000 speed + Marble grave","+10 000 скорости и мраморная могила"}
L.Rows["giftLike"]={"1. Like the game (optional)","1. Поставь лайк игре (необязательно)"}
L.Rows["giftFavorite"]={"2. Favorite (optional)","2. В избранное (необязательно)"}
L.Rows["giftJoin"]={"3. Join the community","3. Вступить в сообщество"}
L.Rows["giftHint"]={"Like on the experience page. Only community membership is needed for the gift.","Лайк можно поставить на странице игры. Для награды нужно только членство в сообществе."}
L.Rows["AutoFire"]={"Automatic fire","Автоогонь"}
L.Rows["ShowRanges"]={"Action ranges","Радиусы действий"}
L.Rows["GuideArrows"]={"Guide arrows","Стрелки-подсказки"}
L.Rows["ShiftSlow"]={"Shift: slow mode","Shift: медленный режим"}
L.Rows["CameraShake"]={"Camera shake","Тряска камеры"}
L.Rows["MusicVolume"]={"Music volume","Громкость музыки"}
L.Rows["SfxVolume"]={"Sound volume","Громкость звуков"}
L.Rows["boardHouse"]={"Upgrade house","Улучшить дом"}
L.Rows["boardField"]={"Add a bed","Добавить грядку"}
L.Rows["boardGraves"]={"Add a grave plot","Добавить место могилы"}
L.Rows["boardGuards"]={"Add a guard","Добавить сторожа"}
L.Rows["boardCrypt"]={"Expand crypt +10","Расширить склеп +10"}
L.Rows["boardPetSlots"]={"Add a pet slot","Добавить слот питомца"}
L.Rows["boardTreadmill"]={"Upgrade treadmill","Улучшить дорожку"}
L.Rows["boardLock"]={"Gate lock","Замок ворот"}
L.Rows["boardLevel"]={"Level {n} > {next}","Уровень {n} > {next}"}
L.Rows["boardMax"]={"Maximum","Максимум"}
L.Rows["boardCredit"]={"Use upgrade credit","Применить улучшение"}
L.Rows["boardReady"]={"Lock gate","Закрыть ворота"}
L.Rows["boardBusy"]={"In progress · {n}s","Строится · {n} с"}
L.Rows["boardNeedHouse"]={"Upgrade the house first","Сначала улучши дом"}
L.Rows["boardStep"]={"+{n}/step","+{n}/шаг"}
L.Rows["lockWait"]={"Ready in {n}s","Готово через {n} с"}
L.Rows["dexUnlocked"]={"Unlocked: {n}/44","Открыто: {n}/44"}
L.Rows["dexThreshold"]={"{n}/11 types","{n}/11 типов"}
L.Rows["dexClaimed"]={"Claimed","Получено"}
L.Rows["dexPage_None"]={"Regular","Обычные"}
L.Rows["dexPage_Golden"]={"Golden","Золотые"}
L.Rows["dexPage_Lunar"]={"Lunar","Лунные"}
L.Rows["dexPage_Rainbow"]={"Rainbow","Радужные"}
L.Rows["dexRewardLine"]={"{coins} Zombucks · +{speed} speed","{coins} зомбуксов · +{speed} скорости"}
L.Rows["dexLocked"]={"Discover more types","Открой больше типов"}
L.Rows["slotItems"]={"Items","Предметы"}
L.Rows["damage"]={"Damage","Урон"}
L.Rows["killToast"]={"Mutant defeated +{n}","Мутант уничтожен +{n}"}
L.Rows["shoot"]={"Fire","Огонь"}
L.Rows["placeItem"]={"Place","Поставить"}
L.Rows["roadJokeYard"]={"No parking. Even after death.","Не парковаться. Даже после смерти."}
L.Rows["roadJokeMall"]={"Brains: buy one, think twice.","Мозги по акции. Думай дважды."}
L.Rows["roadJokeFactory"]={"Do not taste the green stuff.","Зелёное не пробовать!"}
L.Rows["roadJokeClinic"]={"No queue. Everyone ran away.","Очереди нет. Все убежали."}
L.Rows["roadJokeChief"]={"The doctor will see you... run!","Главврач примет… бегом!"}
L.Rows["roadChiefDistance"]={"Chief physician: {n} studs →","До Главврача: {n} стад →"}
-- Grow a Monster setting; legacy vendor art remains available.
L.Rows["title"]={"GROW A MONSTER","ВЫРАСТИ МОНСТРА"}
L.Rows["dex"]={"Monsterdex","Монстродекс"}
L.Rows["dexReward"]={"Monsterdex reward","Награда Монстродекса"}
L.Rows["Field"]={"Yard","Участок"}
L.Rows["placeWorker"]={"This monster earns income anywhere in your yard.","Монстр приносит доход в любом месте участка."}
L.Rows["placeDefender"]={"This monster earns income anywhere in your yard.","Монстр приносит доход в любом месте участка."}
L.Rows["guideField"]={"Take a monster from the crypt and place it anywhere free in your yard. Every placed monster earns income.","Возьми монстра из склепа и поставь на свободном месте участка. Каждый размещённый монстр приносит доход."}
L.Rows["zombieCard"]={"Monster","Монстр"}
L.Rows["placeReturned"]={"The monster returned to the crypt.","Монстр вернулся в склеп."}
L.Rows["placeFieldFull"]={"No room for more monsters.","Не хватает места для монстров."}
L.Rows["guideDig"]={"Place a grave anywhere in the cemetery, clear of the crypt. Wait until ready, then hold Dig beside it. Your monster goes to the crypt.","Поставь могилу в свободном месте кладбища, вне склепа. Дождись готовности и удерживай «Выкопать». Монстр попадёт в склеп."}
L.Rows["guideHome"]={"Merge three monsters of the same kind, rarity and star level. The best mutation stays.","Объединяй трёх монстров одного вида, редкости и звёздности. Лучшая мутация сохранится."}
L.Rows["mergeHint"]={"Three monsters of the same kind, rarity and stars gain a star. The best mutation stays.","Три монстра одного вида, редкости и звёздности получат новую звезду. Лучшая мутация сохранится."}
L.Rows["mergeNeedThree"]={"Choose three matching monsters.","Выбери трёх одинаковых монстров."}
L.Rows["mergeNone"]={"No matches yet. Dig up more monsters!","Пока нечего сливать. Выкапывай ещё монстров!"}
L.Rows["quest_dig"]={"Dig up {n} monsters","Выкопай монстров: {n}"}
L.Rows["quest_rare"]={"Dig up an Uncommon monster or better","Выкопай необычного монстра или круче"}
L.Rows["statuePlaque"]={"Best monster: {zombie}. Owner: {name}","Лучший монстр: {zombie}. Хозяин: {name}"}
L.Rows["mutantNewbie"]={"New player protection: your monster is safe!","Защита новичка: твой монстр в безопасности!"}
L.Rows["mutantStolen"]={"A cultist took {n} Zombucks! Your monster needs rest.","Культист стащил {n} зомбуксов! Монстру нужен отдых."}
L.Rows["empty"]={"No monsters yet. Dig your first grave!","Монстров пока нет. Выкопай первую могилу!"}
L.Rows["tutorialField"]={"② Take a monster from the crypt and place it in your yard","② Возьми монстра в склепе и поставь на участке"}
L.Rows["tutorialDone"]={"Grow your monster collection. Protect it at night!","Собирай монстров и защищай их ночью!"}
L.Rows["DeerFarmer"]={"Farmer Deer","Олень-фермер"}
L.Rows["DeerPunk"]={"Punk Deer","Олень-нефор"}
L.Rows["DeerAssassin"]={"Assassin Deer","Олень-убийца"}
L.Rows["DeerChief"]={"Chief Physician","Главврач"}
L.Rows["roadForest"]={"1. FOREST","1. ЛЕС"}
L.Rows["roadFactory"]={"2. ABANDONED FACTORY","2. ЗАБРОШЕННЫЙ ЗАВОД"}
L.Rows["roadDarkForest"]={"3. DARK FOREST","3. МРАЧНЫЙ ЛЕС"}
L.Rows["roadVillage"]={"4. ABANDONED VILLAGE","4. ЗАБРОШЕННАЯ ДЕРЕВНЯ"}
L.Rows["roadCave"]={"5. CULTIST CAVE","5. ПЕЩЕРА КУЛЬТИСТОВ"}
L.Rows["roadHospital"]={"6. ABANDONED HOSPITAL","6. ЗАБРОШЕННАЯ БОЛЬНИЦА"}
L.Rows["chiefGrave"]={"CHIEF PHYSICIAN GRAVE","МОГИЛА ГЛАВВРАЧА"}
L.Rows["chiefGraveDropped"]={"The Chief dropped a special grave! Carry it home.","Из Главврача выпала особая могила! Доставь её домой."}
L.Rows["found"]={"Collection: {n}/52","Коллекция: {n}/52"}
L.Rows["dexUnlocked"]={"Unlocked: {n}/52","Открыто: {n}/52"}
L.Rows["dexThreshold"]={"{n}/{total} types","{n}/{total} видов"}
L.Rows["roadSpeed1"]={"Recommended speed: 900","Скорость от 900"}
L.Rows["roadSpeed2"]={"Recommended speed: 10K","Скорость от 10К"}
L.Rows["roadSpeed3"]={"Recommended speed: 40K","Скорость от 40К"}
L.Rows["roadSpeed4"]={"Recommended speed: 170K","Скорость от 170К"}
L.Rows["roadSpeed5"]={"Recommended speed: 700K","Скорость от 700К"}
L.Rows["roadSpeed6"]={"Recommended speed: 2.5M","Скорость от 2.5М"}
L.Rows.locationForest={"Forest","Лес"}
L.Rows.locationDarkForest={"Dark Forest","Мрачный лес"}
L.Rows.locationHospital={"Abandoned Hospital","Заброшенная больница"}
L.Rows.locationVillage={"Abandoned Village","Заброшенная деревня"}
L.Rows.locationCave={"Cultist Cave","Пещера культистов"}
L.Rows.locationFactory={"Abandoned Factory","Заброшенный завод"}
L.Rows.locationSpeed={"Recommended speed > {speed}","Рекомендуемая скорость > {speed}"}
L.Rows.Imp={"Cultist","Культист"}
L.Rows.Spitter={"Hunter","Охотник"}
L.Rows.Bubble={"Parasite cultist","Культист с паразитом"}
L.Rows.Chief={"Chief Physician","Главврач"}
L.Rows.mutantWave={"Cultists are approaching your farm!","Культисты приближаются к ферме!"}
function L.compact(n,locale)
 local magnitude=math.abs(n);local div,suffix=1,""
 if magnitude>=1e9 then div,suffix=1e9,"B" elseif magnitude>=1e6 then div,suffix=1e6,"M" elseif magnitude>=1e3 then div,suffix=1e3,"K" end
 local value=n/div;local decimals=div==1 and 0 or math.abs(value)<100 and 2 or 1
 local text=L.number(value,locale,decimals)
 if decimals>0 then text=text:gsub("0+$",""):gsub("[.,]$","") end
 return text..suffix
end
function L.text(key,locale,args)
 local row=L.Rows[key]
 local text=row and (row[L.normalize(locale)=="ru" and 2 or 1] or row[1]) or key
 return (text:gsub("{([%w_]+)}",function(name)
  local value=args and args[name]
  return value~=nil and tostring(value) or "{"..name.."}"
 end))
end
function L.install()
 local rs=game:GetService("ReplicatedStorage")
 local t=rs:FindFirstChild("Localization")
 if not t then t=Instance.new("LocalizationTable");t.Name="Localization";t.Parent=rs end
 assert(t:IsA("LocalizationTable"),"ReplicatedStorage.Localization must be a LocalizationTable")
 t.SourceLocaleId="en-us"
 local entries={}
 for k,v in pairs(L.Rows) do table.insert(entries,{Key=k,Source=v[1],Values={en=v[1],ru=v[2]}}) end
 t:SetEntries(entries) -- Refresh existing tables after adding or correcting translations.
 return t
end

L.Rows["ParasiteFarmer"]={"Farmer Parasite","Паразит-фермер"}
L.Rows["ParasitePunk"]={"Punk Parasite","Паразит-нефор"}
L.Rows["ParasiteAssassin"]={"Assassin Parasite","Паразит-убийца"}
L.Rows["StalkerFarmer"]={"Farmer Stalker","Сталкер-фермер"}
L.Rows["StalkerPunk"]={"Punk Stalker","Сталкер-нефор"}
L.Rows["StalkerAssassin"]={"Assassin Stalker","Сталкер-убийца"}
L.Rows["VerityFarmer"]={"Farmer Verity","Верити-фермер"}
L.Rows["VerityPunk"]={"Punk Verity","Верити-нефор"}
L.Rows["VerityAssassin"]={"Assassin Verity","Верити-убийца"}
-- Offline income goes to the farm heap (2026-11-12)
L.Rows.offlineHeap={"While you were away, your farm earned ${n}. Collect it from the money heap!","Пока тебя не было, ферма заработала ${n}. Забери деньги из кучи на ферме!"}
-- Location bosses and their amphitheatres (2026-11-12)
L.Rows.bossHorned={"Horned Alpha","Рогатый вожак"}
L.Rows.bossSiren={"Siren Head","Сиреноголовый"}
-- The rotation (owner, 2026-11-13): Miner (Uncommon), Knight (Epic), King (Mythic) for every family.
for family,names in {Deer={"Deer","Олень",true},Parasite={"Parasite","Паразит",true},Stalker={"Stalker","Сталкер",true},Verity={"Verity","Верити",true},RingMaw={"RingMaw","Кольцевик",false},CaveDweller={"CaveDweller","Пещерник",false}} do
 local en,ru,hyphen=names[1],names[2],names[3]
 for _,look in {{"Miner","шахтёр","Шахтёр"},{"Knight","рыцарь","Рыцарь"},{"King","король","Король"}} do
  if hyphen then
   L.Rows[family..look[1]]={look[1].." "..en,ru.."-"..look[2]}
  else
   L.Rows[family..look[1]]={en.." "..look[1],ru.." "..look[3]}
  end
 end
end
L.Rows.bossRingMaw={"RingMaw","Кольцевик"}
L.Rows.bossPatient={"Patient Zero","Нулевой пациент"}
L.Rows.bossDealer={"The Dealer","Дилер"}
L.Rows.bossPriest={"High Priest","Верховный жрец"}
L.Rows.arena1={"ARENA · HORNED ALPHA","АРЕНА · РОГАТЫЙ ВОЖАК"}
L.Rows.arena2={"ARENA · SIREN HEAD","АРЕНА · СИРЕНОГОЛОВЫЙ"}
L.Rows.arena3={"ARENA · PATIENT ZERO","АРЕНА · НУЛЕВОЙ ПАЦИЕНТ"}
L.Rows.arena4={"ARENA · THE DEALER","АРЕНА · ДИЛЕР"}
L.Rows.arena5={"ARENA · HIGH PRIEST","АРЕНА · ВЕРХОВНЫЙ ЖРЕЦ"}
L.Rows.arena6={"ARENA · CHIEF PHYSICIAN","АРЕНА · ГЛАВВРАЧ"}
L.Rows.bossArena={"Boss arena: {boss}! Beat it to open its graves.","Арена босса: {boss}! Победи его, чтобы открыть могилы."}
L.Rows.bossDefeated={"{name} defeated {boss}!","{name} победил: {boss}!"}
L.Rows.bossGraveDropped={"The boss left a grave! Carry it home.","Босс оставил могилу! Доставь её домой."}
L.Rows.bossGrave={"BOSS GRAVE","МОГИЛА БОССА"}
L.Rows.bossBar={"BOSS","БОСС"}
L.Rows.Leaper={"Leaper","Прыгун"}
L.Rows.Thrower={"Thrower","Метатель"}
-- The padlock over arena graves now names no particular boss.
L.Rows.roadBossFirst={"Defeat this arena's boss first!","Сначала победи босса этой арены!"}
L.Rows.roadBossLock={"🔒 Defeat the boss","🔒 Победи босса"}
-- 2026-11-12, round 2: Monsterdex cards, hiding bushes, shovel stats, the entrance, house levels and the farm's cap.
L.Rows.dexFindHint={"Not found yet","Ещё не найден"}
L.Rows.dexUnlockedAll={"All pages: {n}/{total} found","Всего открыто: {n}/{total}"}
L.Rows.bushHidden={"🌿 In a bush: unseen","🌿 В кустах: тебя не видят"}
L.Rows.shovelStats={"⚔{d}  💫{s}s  ➜{m}","⚔{d}  💫{s}с  ➜{m}"}
L.Rows.signRoadHome={"BACK TO THE FARMS","ОБРАТНО К ФЕРМАМ"}
L.Rows.houseOwner={"{name}'S BASE","БАЗА {name}"}
L.Rows.boardHouseGain={"Farm monsters: {used}/{a} → {b}","Монстров на ферме: {used}/{a} → {b}"}
L.Rows.boardHouseMax={"Farm monsters: {used}/{a}","Монстров на ферме: {used}/{a}"}
L.Rows.boardTreadmillGain={"A step: +{a} → +{b}","Шаг: +{a} → +{b}"}
L.Rows.boardTreadmillMax={"A step: +{a}","Шаг: +{a}"}
L.Rows.boardPetGain={"Pet slots: {a} → {b}","Слоты питомцев: {a} → {b}"}
L.Rows.boardPetMax={"Pet slots: {a}","Слоты питомцев: {a}"}
L.Rows.placeFieldFull={"The farm is full: upgrade the house to place more monsters.","Ферма заполнена: улучши дом, чтобы ставить больше монстров."}
-- Blood Moon and prestige (2026-11-12)
L.Rows.bloodMoonRise={"🩸 BLOOD MOON! {boss} waits in the Blood Moon arena across the island from the ruins road: go and kill it before it gets away! The road is shut.","🩸 КРОВАВАЯ ЛУНА! {boss} ждёт на арене Кровавой луны — напротив дороги в заброшки, за стеной острова. Убей его, пока он не ушёл! Дорога в заброшки закрыта."}
L.Rows.bloodMoonWin={"{boss} is down! Final blow: {name}. Graves are falling from the sky!","{boss} повержен! Последний удар: {name}. С неба падают могилы!"}
L.Rows.bloodMoonLost={"{boss} sank away. The road is open again.","{boss} ушёл. Дорога снова открыта."}
L.Rows.bloodMoonGrave={"Blood Moon grave: {grave}!","Могила Кровавой луны: {grave}!"}
L.Rows.bloodMoonEnough={"You already took {n} Blood Moon graves: leave some for the others!","Ты уже забрал {n} могилы Кровавой луны: оставь другим!"}
L.Rows.bloodMoonBar={"BLOOD MOON","КРОВАВАЯ ЛУНА"}
L.Rows.roadClosed={"The road is shut while the Blood Moon giant is out!","Дорога закрыта, пока гигант Кровавой луны на свободе!"}
L.Rows.roadClosedSign={"CLOSED · BLOOD MOON","ЗАКРЫТО · КРОВАВАЯ ЛУНА"}
L.Rows.boardPrestige={"Prestige","Престиж"}
L.Rows.boardPrestigeLevel={"Prestige {n} → {next}","Престиж {n} → {next}"}
L.Rows.boardPrestigeGain={"Income ×{a} → ×{b} forever","Доход ×{a} → ×{b} навсегда"}
L.Rows.boardPrestigeHouse={"Needs house level {n}","Нужен дом {n} ур."}
L.Rows.prestigeTitle={"Prestige {n}?","Престиж {n}?"}
L.Rows.prestigeBody={"Your farm starts over: coins, monsters, graves, the house and the treadmill go back to the start.\nYou keep pets, the Monsterdex, weapons, shovels, mutagen and speed.\nIncome forever: ×{a} → ×{b}. Price: {price} $.","Ферма начнётся заново: монеты, монстры, могилы, дом и дорожка вернутся к началу.\nОстанутся питомцы, Монстродекс, оружие, лопаты, мутаген и скорость.\nДоход навсегда: ×{a} → ×{b}. Цена: {price} $."}
L.Rows.prestigeYes={"Prestige!","Престиж!"}
L.Rows.prestigeNo={"Not yet","Пока нет"}
L.Rows.prestigeDone={"Prestige {n}! Your income is now ×{m} forever.","Престиж {n}! Теперь твой доход ×{m} навсегда."}
L.Rows.prestigeAll={"{name} reached prestige {n}!","{name} получил престиж {n}!"}
L.Rows.prestigeBusy={"Put down what you carry first.","Сначала положи то, что несёшь."}
-- Pets v3 (2026-11-12): they live on the farm; the old kinds are gone and refunded
L.Rows.DragonHead={"Dragonhead","Драконоголовый"}
L.Rows.BedBanker={"Banker Bed","Банкир-Кровать"}
L.Rows.FacepalmCat={"Facepalm Cat","Котик Фейспалм"}
L.Rows.petAbility_DragonHead={"Patrols the farm, burns raiders: {n} damage","Патрулирует ферму, жжёт налётчиков: {n} урона"}
L.Rows.petAbility_BedBanker={"Farm income ×{n}","Доход фермы ×{n}"}
L.Rows.petAbility_FacepalmCat={"Just a cat. Just a facepalm.","Просто котик. Просто фейспалм."}
L.Rows.petOnFarm={"Lives on the farm","Живёт на ферме"}
L.Rows.petStarterStays={"The Facepalm Cat always lives on your farm.","Котик Фейспалм всегда живёт на твоей ферме."}
L.Rows.petsRefunded={"The old pets have left: you got {n} $ back for them.","Старые питомцы ушли: за них вернули {n} $."}
L.Rows.mutantWave={"Monsters are raiding your farm!","Монстры нападают на ферму!"}
-- 2026-11-13: farm gate and fence, guns earned in the ruins, reload and range upgrades, the hotbar and merge picker
L.Rows.boardFence={"Fence","Забор"}
L.Rows.boardFenceGain={"Gate {a} → {b} HP","Ворота: {a} → {b} прочности"}
L.Rows.boardFenceMax={"Gate {a} HP — the best fence","Ворота: {a} прочности — лучший забор"}
L.Rows.repairGate={"Mend the gate","Починить ворота"}
L.Rows.gateHp={"Gate {n}/{max}","Ворота {n}/{max}"}
L.Rows.gateBrokenTag={"Gate broken!","Ворота сломаны!"}
L.Rows.gateAttacked={"Mutants are breaking your gate!","Мутанты ломают твои ворота!"}
L.Rows.gateBroken={"Your gate is broken! It mends itself in {n} s, or fix it now.","Ворота сломаны! Сами починятся через {n} с — или почини их сам."}
L.Rows.gateRepaired={"Gate mended.","Ворота починены."}
L.Rows.weaponTake={"Take it","Забрать"}
L.Rows.weaponNeedKills={"Kill {n} monsters in {place} to earn it.","Убей {n} монстров в локации «{place}», чтобы получить."}
L.Rows.weaponUnlocked={"New gun earned: {weapon}!","Новое оружие получено: {weapon}!"}
L.Rows.up_Reload={"Reload","Перезарядка"}
L.Rows.up_Range={"Range","Дальность"}
L.Rows.upSeconds={"{n} s","{n} с"}
L.Rows.upStuds={"{n} studs","{n} ст."}
L.Rows.cryptNothing={"No monsters waiting in the crypt.","В склепе нет свободных монстров."}
L.Rows.takeOnFarm={"Take monsters out on your own farm.","Взять монстра можно только на своей ферме."}
L.Rows.mergeChoose={"Choose a monster","Выбери монстра"}
L.Rows.stealNewbie={"Newcomers can't steal graves while their boost lasts.","Пока действует буст новичка, красть могилы нельзя."}
L.Rows.shovePenalty={"You shoved a player: for {n} s graves lift slower, and the monsters come for you!","Ты толкнул игрока: {n} с могилы поднимаются дольше, а монстры идут за тобой!"}
L.Rows.workbench={"WORKBENCH","ВЕРСТАК"}
L.Rows.portalHome={"Home","Домой"}
L.Rows.portalOpen={"You beat the boss! Its main grave is open to its winners, and a portal home stands in the arena for {n} s (an ordinary grave carried through loses 1 rarity, the main one doesn't).","Босс повержен! Главная могила открыта для победителей, а портал домой стоит в арене {n} с (обычная могила в портале теряет 1 редкость, главная — нет)."}
L.Rows.portalUsed={"Home through the portal!","Ты дома — через портал!"}
L.Rows.bossEnraged={"{boss} is enraged: faster and angrier!","{boss} в ярости: быстрее и злее!"}
L.Rows.bloodArenaSign={"BLOOD MOON ARENA","АРЕНА КРОВАВОЙ ЛУНЫ"}
L.Rows.portalDowngrade={"Through the portal your {from} grave became {to}.","Через портал могила «{from}» стала «{to}»."}
L.Rows.portalPenalty={"A carried grave loses 1 rarity","Несомая могила потеряет 1 редкость"}
-- Sleeping bosses (2026-11-13): steal from the hoard and run, or wake it and fight in the shut arena
L.Rows.bossAsleep={"{boss} is asleep. Dig a grave from its hoard and run for the gate: it gives chase! Hit it and the arena shuts: a fight to the end.","{boss} спит. Выкопай могилу из его клада и беги к воротам — он погонится! Ударишь его — арена закроется, бой до конца."}
L.Rows.bossWoke={"{boss} woke up! Run for the gate!","{boss} проснулся! Беги к воротам!"}
L.Rows.bossCaught={"{boss} caught you! The grave went back to its hoard.","{boss} догнал тебя! Могила вернулась в его клад."}
L.Rows.bossEscaped={"You got away: {boss} is left with nothing!","Ты убежал: {boss} остался ни с чем!"}
L.Rows.bossFightLocked={"{boss}: the arena is shut, a fight to the end!","{boss}: арена закрыта, бой до конца!"}
L.Rows.bossSleepsAgain={"{boss} won and went back to sleep.","{boss} победил и снова уснул."}
L.Rows.bossGraveWinners={"Only those who beat the boss can take this grave.","Эту могилу могут взять только победители босса."}
L.Rows.bossFightSign={"⚔ BOSS FIGHT IN PROGRESS","⚔ ИДЁТ БОЙ С БОССОМ"}
L.Rows.bossMainGrave={"BOSS'S MAIN GRAVE","ГЛАВНАЯ МОГИЛА БОССА"}
L.Rows.bossChaseBar={"CHASE!","ПОГОНЯ!"}
return L
