-- Render prototype only. No asset acquisition, input handling, or runtime state.
-- Image callbacks receive x, y, width, height and alpha in the range 0..1.
do
    local duration=3.6
    local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
    local function clamp(v) return math.max(0,math.min(1,v)) end
    local function smooth(v) v=clamp(v);return v*v*(3-2*v) end
    local function color(v,a) return {v,v,v,a} end
    local function cyan(a) return {.32,.82,.94,a} end
    local function center(x,y,text,alpha,size,level)
        local width=draw.GetTextSize(text,size)
        draw.Text(x-width*.5,y,text,color(level or .94,alpha),size)
    end
    local function image(fn,x,y,w,h,alpha)
        if type(fn)=="function" and alpha>0 then fn(x,y,w,h,clamp(alpha)) end
    end
    local function stroke(x1,y1,x2,y2,fraction,alpha,width)
        fraction=clamp(fraction)
        if fraction>0 then draw.Line(x1,y1,x1+(x2-x1)*fraction,y1+(y2-y1)*fraction,color(.89,alpha),width) end
    end
    function app.render_loading_collab(elapsed,sw,sh,reduce_motion)
        if not finite(sw) or not finite(sh) or sw<64 or sh<64 then return {valid=false,duration=duration} end
        elapsed=finite(elapsed) and math.max(0,elapsed) or 0
        local reduced=reduce_motion==true
        local fade=math.min(smooth(elapsed/.34),smooth((duration-elapsed)/.55))
        local ares_in=smooth((elapsed-.1)/.6)
        local vector_in=smooth((elapsed-.98)/.66)
        local cross_one=smooth((elapsed-.66)/.29)
        local cross_two=smooth((elapsed-.88)/.29)
        local footer_in=smooth((elapsed-1.58)/.48)
        if reduced then ares_in=1;vector_in=1;cross_one=1;cross_two=1;footer_in=1 end
        local scale=math.min(1,(sw-32)/572,(sh-32)/292)
        local w,h=572*scale,292*scale
        local x,y=(sw-w)*.5,(sh-h)*.5
        if not reduced then y=y+(1-smooth(elapsed/.64))*7*scale end
        local left,right,middle=x+156*scale,x+416*scale,x+w*.5
        local mark_y=y+63*scale
        local ares_shift=not reduced and (1-ares_in)*10*scale or 0
        local vector_shift=not reduced and (1-vector_in)*14*scale or 0
        local aa,va=fade*ares_in,fade*vector_in
        draw.RectFilled(0,0,sw,sh,color(0,.4*fade),0)
        -- Fixed contour glow: six bands, independent of resolution and time.
        for i=6,1,-1 do
            local spread=i*2*scale
            draw.Rect(x-spread,y-spread,w+spread*2,h+spread*2,color(.9,fade*.017*(7-i)/6),11*scale+spread,2*scale)
        end
        draw.RectFilled(x,y,w,h,color(.022,.985*fade),11*scale)
        draw.Rect(x,y,w,h,color(.36,.54*fade),11*scale,1)
        draw.Line(x+18*scale,y+.5*scale,x+w-18*scale,y+.5*scale,color(.84,.28*fade),1)
        draw.Text(x+23*scale,y+20*scale,"A R E S  V2",color(.78,.72*fade),10*scale)
        local meta="STARTUP SEQUENCE"
        local meta_width=draw.GetTextSize(meta,9*scale)
        draw.Text(x+w-23*scale-meta_width,y+21*scale,meta,color(.48,.8*fade),9*scale)
        draw.Line(x+23*scale,y+43*scale,x+w-23*scale,y+43*scale,color(.2,.72*fade),1)
        -- A compact nested halo stays behind the Vector silhouette. No particles.
        local halo=va*(reduced and 1 or (.9+.1*math.sin(math.max(0,elapsed-1.55)*2)))
        if type(app.preview_loading_aura)=="function" then
            image(app.preview_loading_aura,right-98*scale+vector_shift,mark_y-19*scale,196*scale,150*scale,halo*.7)
        else
            for i=5,1,-1 do
                local radius=(25+i*7)*scale
                draw.CircleFilled(right+vector_shift,mark_y+54*scale,radius,cyan(halo*(.007+(6-i)*.0015)),48)
            end
        end
        image(app.preview_loading_ares,left-71*scale-ares_shift,mark_y,142*scale,112*scale,aa)
        image(app.preview_loading_vector,right-71*scale+vector_shift,mark_y,142*scale,112*scale,va)
        local cy=mark_y+55*scale
        local arm=10*scale
        stroke(middle-arm,cy-arm,middle+arm,cy+arm,cross_one,fade*.8,1.5*scale)
        stroke(middle+arm,cy-arm,middle-arm,cy+arm,cross_two,fade*.8,1.5*scale)
        center(left-ares_shift,y+188*scale,"A R E S",aa,16*scale,.94)
        center(right+vector_shift,y+188*scale,"V E C T O R",va,14*scale,.91)
        -- A short travelling highlight passes once while the finished lockup holds.
        if not reduced and elapsed>=1.65 and elapsed<=2.9 then
            local travel=clamp((elapsed-1.65)/1.25)
            local sweep_x=x+24*scale+(w-48*scale)*travel
            for i=1,8 do
                local tail=(8-i)*6*scale
                local sx=math.max(x+24*scale,sweep_x-tail)
                local ex=math.min(x+w-24*scale,sx+6*scale)
                if ex>sx then draw.Line(sx,y+43*scale,ex,y+43*scale,color(1,fade*.023*i),1) end
            end
        end
        local track_x,track_y,track_w=x+24*scale,y+235*scale,w-48*scale
        local progress=smooth(elapsed/duration)
        draw.RectFilled(track_x,track_y,track_w,1.5*scale,color(.16,.85*fade),1)
        draw.RectFilled(track_x,track_y,track_w*progress,1.5*scale,color(.86,.88*fade),1)
        local caption_alpha=fade*footer_in
        local footer_size=12*scale
        local lead_width=draw.GetTextSize("Powered by ",footer_size)
        local brand_width=draw.GetTextSize("VECTOR",footer_size)
        local footer_x=middle-(lead_width+brand_width)*.5
        draw.Text(footer_x,y+253*scale,"Powered by ",color(.8,caption_alpha*.86),footer_size)
        draw.Text(footer_x+lead_width,y+253*scale,"VECTOR",cyan(caption_alpha*.94),footer_size)
        -- Export stable geometry for fixture verification without maintaining state.
        return {valid=true,duration=duration,elapsed=elapsed,alpha=fade,x=x,y=y,w=w,h=h,scale=scale,
            ares_x=left-71*scale-ares_shift,vector_x=right-71*scale+vector_shift,mark_y=mark_y,
            mark_w=142*scale,mark_h=112*scale,ares_alpha=aa,vector_alpha=va,footer_alpha=caption_alpha,
            progress=progress,cross_one=cross_one,cross_two=cross_two}
    end
end
