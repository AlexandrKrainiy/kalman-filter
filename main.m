i=1;
nbimage=1;
while 1 <= nbimage
img1= imread('acA2040-90um__21791513__20161010_155121518_0610.tiff'); % reading image in the folder
I = (img1);
%img=imread(filename);
%I=(img1);
fn=1;
nb_fish=1;
y_fish_fn=0;
x_fish_fn=0;
number_fish=9;
for nn=1:number_fish


if nn>1
x_fish_fn(x_fish_fn==0)=NaN;
y_fish_fn(y_fish_fn==0)=NaN;
h5 = figure('visible','on');
imshow(I)

sz=size(y_fish_fn);
sz1=sz(1,1);
for asd1=1:sz1;
hold on 
fig4=plot(x_fish_fn(asd1,:),y_fish_fn(asd1,:));
end 
end

figure;
J=roifill(I);
BW=im2bw((J-I),0.01);
BW2 = bwmorph(BW,'erode');
BW2 = bwmorph(BW2,'dilate');
BW2 = bwmorph(BW2,'dilate');
BW2 = bwmorph(BW2,'dilate');
[B,L,N,A] = bwboundaries(BW2);




asd=1;
for k=1:N
boundary=0; 
boundary = B{k};
if(length(B{k})> 400)
Fish_Boundary{nb_fish} = B{k};
col=0;
row=0;
col=boundary(:,2);
row=boundary(:,1);
A=0;
C=0;
A=unique(col);
C=unique(col);
%%%%%%%%%%

for l = length(A)+1: length(col) % adding the extra dimension equal to col vector 
A(l)=1;
end
for m=1:length(col)
a=A(m);
if a>1
idx = find(col==a);
Y(m)=mean(row(idx));%%%%% midline is extracted %%%
end
end
midline_final=zeros(size(C));
Y(isnan(Y))=0;
for n=1:length(C)
midline_final(n) = (Y(n));
end

x=0
x=C;
y=0;
y=midline_final;
%%%%%midline smoothning
p=0;
mu=0;
f=0;


[p,~,mu] = polyfit(x,y,5);
f= polyval(p,x,[],mu);
y_fish = f;

y_fish_fn(fn,1:length(f))=f';
x_fish_fn(fn,1:length(x))=x';

%%%%% end of midline
eval(sprintf('x_fish%d = x', fn));
eval(sprintf('y_fish%d = y_fish', fn));
% figure(1)
% h1=plot(x ,smooth(x,y,0.1,'rloess'), 'r','LineWidth',2);
% hold on
% str =['fish' sprintf('%d',fn)]
xt= max(x);
x_temp=eval(sprintf('x_fish%d', fn));
a_x(fn)=max(x_temp);
y_temp= eval(sprintf('y_fish%d', fn))
a_y(fn)=mean(y_temp(find(x_temp==max(x_temp))));
clear x_temp
clear y_temp
% idx = find(x== xt );
% yt= mean(y(idx,1))
% text(xt+5,yt,str) 
fn=fn+1 
nb_fish=nb_fish+1; 
end

end


%%
% y_fish_final=sortrows(y_fish_fn)
% [val ind]=sortrows(y_fish_fn);
% x_fish_final=x_fish_fn(ind,:);
%%
close all

x_boundary{nn,1}=col;
y_boundary{nn,1}=row;








end
x_fish_fn(x_fish_fn==0)=NaN;
y_fish_fn(y_fish_fn==0)=NaN;
%[B,L,N,A] = bwboundaries(I);
% 
% BW=im2bw((J-I),0.02);
% I= imcrop(BW, rect);
%I= imcrop(img1, rect);

% baseFileName1 = sprintf('xy_midline%d.mat',i);
% fullFileName1 = fullfile('B:\new experiments\3fish\pair3\22lpm\take3\midline', baseFileName1); 
% save(fullFileName1 ,'x_top','y_top','x_middle','y_middle','x_bottom','y_bottom','B')
% baseFileName = sprintf('ashraf%d.png',i);
% fullFileName = fullfile('B:\new experiments\3fish\pair3\22lpm\take3\FISH', baseFileName); 
% print(h3,fullFileName,'-dpng','-r300');
% close (h3)
sz=size(y_fish_fn);
sz1=sz(1,1);
h2 = figure('visible','on');
imshow(I)
hold on 
for pt=1:sz1
fig3=plot(x_fish_fn(pt,:),y_fish_fn(pt,:));
hold on
end





end
