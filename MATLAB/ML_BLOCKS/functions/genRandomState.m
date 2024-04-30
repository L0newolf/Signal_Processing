function [] = genRandomState(  )

global RED;
global BLUE;
global GREEN;
global BLANK;

global stateRows;
global stateCols;
global curState;

curState = zeros(stateRows,stateCols);

curVal = 0;
redCount = 0;
blueCount = 0;
greenCount = 0;
blankCount = 0;

i=1;

while(i<stateRows+1)
    j=1;
    while(j<stateCols+1)
        curVal = randi(stateRows,1,1) - 1;

        switch curVal
            case RED 
                if(redCount ~= stateCols) 
                    curState(i,j) = RED;
                    redCount = redCount + 1;
                else
                    j=j-1;
                end
            case BLUE 
                if(blueCount ~= stateCols)
                curState(i,j) = BLUE;
                blueCount = blueCount + 1;
                else
                    j=j-1;
                end
            case GREEN 
                if(greenCount ~= stateCols)
                curState(i,j) = GREEN;
                greenCount = greenCount + 1;
                else
                    j=j-1;
                end
            case BLANK 
                if(blankCount ~= stateCols)
                curState(i,j) = BLANK;  
                blankCount = blankCount + 1;
                else
                    j=j-1;
                end
        end
        
        j=j+1;
        
    end
    i=i+1;
end

x = ['RED Count = ',num2str(redCount),' BLUE Count = ',num2str(blueCount),...
    ' GREEN Count = ',num2str(greenCount),' BLANK COUNT = ',num2str(blankCount)];
disp(x);
end


