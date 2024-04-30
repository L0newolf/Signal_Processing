function [ state ] = setDefaultState()

global RED;
global BLUE;
global GREEN;
global BLANK;

global stateRows;
global stateCols;

curVal = 0;

    for i=1:stateCols
        switch i
            case 1
                curVal = BLANK;
            case 2
                curVal = GREEN;
            case 3
                curVal = RED;
            case 4
                curVal = BLUE;
        end
        
        for j=1:stateRows
            state(j,i) = curVal;
        end
    end
end

