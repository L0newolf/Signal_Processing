function [  ] = drawFigure(figNum,state)

global colourRed;
global colourGreen;
global colourBlue;
global colourBlank;

global startX;
global startY;

global blockWidth;
global blockHeight;

global RED;
global BLUE;
global GREEN;
global BLANK;

global stateRows;
global stateCols;

figure(figNum);

for i=1:stateRows
    for j=1:stateCols
        switch state(i,j)
            case BLANK
                curColour = colourBlank;
            case RED
                curColour = colourRed;
            case BLUE
                curColour = colourBlue;
            case GREEN
                curColour = colourGreen;
        end
        
        rectangle('Position',[startX+(j-1)*blockWidth startY+(i-1)*blockHeight blockWidth blockHeight],'FaceColor',curColour);
        
    end
end


xlim([0 9]);
ylim([0 10]);
set(gca,'xtick',[]);
set(gca,'ytick',[]);


end

