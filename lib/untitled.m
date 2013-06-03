newInfection = sum(~isnan(SDS.males.HIV_positive))+sum(~isnan(SDS.females.HIV_positive))- sum(SDS.males.HIV_positive==0)
testTimes = sum(SDS.tests.ID~=0)
arvTimes = sum(SDS.ARV.ID~=0)