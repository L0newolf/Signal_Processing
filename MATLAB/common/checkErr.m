function [ err ] = checkErr( arr1,arr2 )

err=0;
for i=1:length(arr1)
    if(arr1(i)~=arr2(i))
        err=err+1;
    end
end


end

