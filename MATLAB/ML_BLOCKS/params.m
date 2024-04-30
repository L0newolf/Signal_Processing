
global colourRed;
colourRed = [1,0,0];
global colourGreen;
colourGreen = [0,1,0];
global colourBlue;
colourBlue = [0,0,1];
global colourBlank;
colourBlank = [1,1,1];

global startX;
startX = 2;
global startY;
startY = 2;

global blockWidth;
blockWidth = 1;
global blockHeight;
blockHeight = 1;

global RED;
RED = 1;
global BLUE;
BLUE = 2;
global GREEN;
GREEN = 3;
global BLANK;
BLANK = 0;

global numBlocks;
numBlocks = 4;

global stateRows;
stateRows = 4;
global stateCols;
stateCols = 4;
global curState;
curState = zeros(stateRows,stateCols);

global maxTableSize;
maxTableSize = 1024;
global stateList;
stateList = zeros(maxTableSize,stateRows,stateCols);
global numStates;
numStates = 0;

global transList;
transList = [];
global transCount;
transCount = 0;
global stateId;
stateId = 0;

