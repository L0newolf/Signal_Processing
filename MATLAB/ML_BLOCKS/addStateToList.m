function [] = addStateToList( startingState)

global stateList;
global numStates;
global stateId;

if (numStates == 0)
    numStates = 1;
    stateList(numStates,:,:) = startingState;
    stateId =1;
else
    found = 0;
    for i=1:numStates
        if(reshape(stateList(i,:),[4,4]) == startingState)
            found = 1;
            stateId =i;
        end
    end
    if(found ==0)
        numStates = numStates+1;
        stateList(numStates,:,:) = startingState;
        stateId =numStates;
    end
end

end

