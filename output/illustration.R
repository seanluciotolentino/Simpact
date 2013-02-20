scenarios<-c('basic','age','concurrent')
for (scenario in scenarios){

datafile = sprintf('%spop_%04d_%s.csv',folder,fileindex,scenario)
data<-read.csv(datafile)
relation<-simpact.mixing(folder, fileindex, scenario, period=c(1,11))
write.csv(relation,file = sprintf('%s%s_relation.csv',folder,scenario))
time<-seq(0,10,by = 0.2)

# 1. age mixing : see relation
# 2. concurrency
# 3. duration
# 4. degree
# 5. SIR ananog

# 2. concurrency, 5. SIR
concurrent<-c()
S<-c()
I<-c()
infect<-c()
i<-1
for (t in time){
  
  rt<-relation[relation$start.time<=t&relation$end.time>t,]
  male.concurr<-sum(table(rt$male.id)>1)
  female.concurr<-sum(table(rt$female.id)>1)
  concurr<-male.concurr+female.concurr
  total<-length(unique(rt$male.id))+length(unique(rt$female.id))
  concurrent[i]<-round(concurr/total,digit=3)
  
  pop<-data
  pop$deceased[is.na(pop$deceased)]<-Inf
  pop$hiv.positive[is.na(pop$hiv.positive)]<-Inf
  pop<-pop[pop$born<t&pop$deceased>t,]
  infect[i]<-sum(pop$hiv.positive>=(t-1)&pop$hiv.positive<t)
  I[i]<-sum(pop$hiv.positive<t)
  S[i]<-nrow(pop)-I[i]
  i<-i+1
}

out<-data.frame(concurrent,I,S,infect)
write.csv(out,file = sprintf('%s%s_concurrent_SIR.csv',folder,scenario))


# 4. cum degree
rt<-relation[relation$start.time<=15&relation$end.time>0,c(1,2)]
rid<-paste(rt$male.id,rt$female.id)
for (i in 1:nrow(rt)){
  this<-paste(rt$male.id[i],rt$female.id[i])
  if (length(which(rid==this))==0){
    rt$male.id[i]<-0
  }
}
rt<-rt[rt$male.id!=0,]

degree <- matrix(0,nrow=100,ncol=2)
colnames(degree)<-c('Males degreee','Females degree')

male.degree<-table(rt$male.id)
male.degree<-table(male.degree)
for (i in 1:length(male.degree)){degree[i,1]<-male.degree[i]}

female.degree<-table(rt$female.id)
female.degree<-table(female.degree)
for (i in 1:length(female.degree)){degree[i,2]<-female.degree[i]}

degree<-data.frame(degree)
write.csv(degree,file = sprintf('%s%s_degree.csv',folder,scenario))

rt<-graph.data.frame(rt)
}