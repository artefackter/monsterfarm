"""Release forms: preserve approved V5 creatures; add Parasite and Stalker pairs."""
import copy
import assets_monster_forms_v5 as previous
import assets_monster_forms as posing
import assets_collection_v2 as collection
import kit

JOINTS=previous.JOINTS
FORMS=previous.FORMS
CHECKS=previous.CHECKS

def build():
    previous.build()
    for family in ('Parasite','Stalker'):
        for role in ('Farmer','Punk','Assassin'):
            key=family+'_'+role
            FORMS[key]={}
            for state in ('Passive','Aggressive'):
                a=collection.character(family,role,expression=state)
                del kit.ASSETS[key]
                a.name=key+'_'+state
                kit.ASSETS[a.name]=a
                JOINTS[a.name]=copy.deepcopy(collection.JOINTS[key])
                for p in a.parts:
                    if p.name.startswith('Tendril'):p.attach=p.name
                if state=='Aggressive':
                    posing.pose_group(a,'Head',(8,0,0))
                    for side,group in ((-1,'ArmR'),(1,'ArmL')):
                        posing.pose_group(a,group,(-12,-side*8,0))
                    if family=='Parasite':
                        for side,group in ((-1,'TendrilR'),(1,'TendrilL')):
                            posing.pose_group(a,group,(18,0,-side*12))
                CHECKS[a.name]={'mouthOpen':True,'eyeColor':'red' if state=='Aggressive' else 'amber' if family=='Parasite' else 'cyan',
                                'widerMouth':state=='Aggressive','costume':role,
                                'familySpecificExtremities':True}
                FORMS[key][state]=a.name
    assert len(kit.ASSETS)==36
