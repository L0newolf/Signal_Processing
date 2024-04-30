function [] = sortToTargetState(targetState)

global stateRows;
global stateCols;
global curState;
global stateId;
global transList;

for i=1:stateRows
    for j=1:stateCols
        
        curTargetVal = targetState(i,j);
        
        if(curState(i,j) ~= curTargetVal)
            
            k=i;
            l=j;
            while(curState(k,l) ~= curTargetVal)
                if(l==stateCols)
                    l=1;
                    k=k+1;
                else
                    l=l+1;
                end
            end
            
            curState(k,l) = curState(i,j);
            curState(i,j) = curTargetVal;
    
        end
        
        addStateToList(curState);
        if(stateId ~= transList(length(transList)))
            transList = [transList stateId];
        end
        %drawFigure(2,curState);
        pause(.1);
        
    end
end


end

