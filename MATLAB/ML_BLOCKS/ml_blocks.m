

clear all;
clc;

run('params');

numLoops = 1000;

transTable = zeros(numLoops,stateRows*stateCols);
transPtr = 1;

targetState = setDefaultState();
addStateToList(targetState);
%drawFigure(1,targetState);

for i=1:numLoops
    transList = [];
    
    genRandomState();
    
    startingState = curState;
    addStateToList(startingState);
    transList = [transList stateId];
    %drawFigure(2,curState);
    pause(1);
    sortToTargetState(targetState);
    
    for j=1:length(transList)
        %drawFigure(4,reshape(stateList(transList(j),:),[4,4]));
        pause(.5);
    end
    
    if(transList(1) ~= transTable(transPtr,1))
        for j=1:length(transList)
            transTable(transPtr,j) = transList(j);
        end
        transPtr = transPtr+1;
    end
    
end

for i=1:numStates
    %drawFigure(3,reshape(stateList(i,:),[4,4]));
    pause(.5);
end

