function cc=midpoint(pindex,grain)
len=length(pindex);
T1=pindex(1);T2=pindex(len);
[M,N]=size(grain);
 grain1 = false(size(grain));
 grain1(pindex) = true;
 SS=sum(grain1==1);
n1=floor(T1/M+0.5);n2=floor(T2/M+0.5);
flag=true;
if(abs(n1-n2)>85)
    flag=false;
end
if(flag)
    SS1=SS(find(SS>0));
    if(length(SS1)>5)
        SS11=SS1(3:end-2);
        s1=sum(SS11>3);
        if(s1>0)
            flag=false;
        end
    end
end
if(flag)
    f=pindex(1);s=0;
    for i=2:len
        if(pindex(i)-pindex(i-1)<50)
            s=pindex(i);
            continue;
        elseif(i~=N)
           T=(f+s)/2;
           T=floor(T+0.5);
           n=floor(T/M)+1;
           m=T-(n-1)*M;
           grain(m,n)=true;
           f=pindex(i);s=0;
        else
            if(s==0)
                T=f;
            else
                 T=(f+s)/2;
            end
            T=floor(T+0.5);
           n=floor(T/M)+1;
           m=T-(n-1)*M;
           grain(m,n)=true;
           f=pindex(i);s=0;
        end

    end
else
     index=[];first=[];second=[];
     for i=1:length(SS)
         if(SS(i)==0)
             continue;
         end
         index=[index,i];
         for j=1:M
             if(grain1(j,i)==1)
                 first=[first,j];
                 break;
             end
         end
         for j=M:-1:1
             if(grain1(j,i)==1)
                 second=[second,j];
                 break;
             end
         end
        
     end
     diff=second-first;
     ff=0;
     if(max(diff)>13)
         ff=1;
     end
     no=min(length(index),randi([45,75],1));
     if(ff==0)
         
         for i=no-3:no
             spa=(i-61)/2;
             fp=floor(first(i)+spa);
             sp=floor(second(i)-spa);
             
             grain(fp,index(i))=true;
              grain(sp,index(i))=true;
              if(sp-fp<=4)
                  grain(fp:sp,index(i))=true;
                  break;
              end
         end
         inum=0;
          for i=length(index)-no-8:-1:length(index)-no
              inum=inum+1;
             spa=inum/4;
             fp=floor(first(i)+spa);
             sp=floor(second(i)-spa);
             grain(fp,index(i))=true;
              grain(sp,index(i))=true;
              if(sp-fp<=4)
                  grain(fp:sp,index(i))=true;
                  break;
              end
         end
         f=pindex(1);s=0;
        for i=2:len
            if(pindex(i)-pindex(i-1)<50)
                s=pindex(i);
                continue;
            elseif(i~=N)
               T=(f+s)/2;
               T=floor(T+0.5);
               n=floor(T/M)+1;
               m=T-(n-1)*M;
               grain(m,n)=true;
               f=pindex(i);s=0;
            else
                if(s==0)
                    T=f;
                else
                     T=(f+s)/2;
                end
                T=floor(T+0.5);
               n=floor(T/M)+1;
               m=T-(n-1)*M;
               grain(m,n)=true;
               f=pindex(i);s=0;
            end
        end
     else
         numo=0;
        for i=1:length(index)
            for k=first(i)+2:M
                 if(grain1(k,index(i)))
                     if(k-first(i)<=10)
                          T=(first(i)+k)/2;
                           T=floor(T+0.5);
                           grain(T,index(i))=true;
                     else
                         T=(first(i)+first(i)+10)/2;
                          T=floor(T+0.5);
                          grain(T,index(i))=true;
                           grain(first(i)+10,index(i))=true;
                           if(numo==0)
                                grain(first(i)+10,index(i))=true;
                           end
                     end
                     break;
                 end
            end
            for k=second(i)-2:-1:1
                 if(grain1(k,index(i)))
                     if(second(i)-k<=10)
                          T=(second(i)+k)/2;
                           T=floor(T+0.5);
                           grain(T,index(i))=true;
                     else
                         T=(second(i)+second(i)-7)/2;
                          T=floor(T+0.5);
                          grain(T,index(i))=true;
                           grain(second(i)-7,index(i))=true;
                     end
                     break;
                 end
            end
         end
         end
     end

cc=grain;
end