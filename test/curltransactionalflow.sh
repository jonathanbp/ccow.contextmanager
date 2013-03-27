participantCoupon=$(curl -H "Accept: text/html" http://localhost:3000/ContextManager/JoinCommonContext\?applicationName\=myapp2\&contextParticipant\=http://localhost:8001)
contextCoupon=$(curl -H "Accept: text/html" http://localhost:3000/ContextManager/StartContextChanges\?participantCoupon\=$participantCoupon)
responses=$(curl http://localhost:3000/ContextManager/EndContextChanges\?contextCoupon\=$contextCoupon)
echo $responses