----------------------------------------------------------------------
--
-- Copyright (c) 2012 Clement Farabet
-- 
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
----------------------------------------------------------------------
-- description:
--     webterm - a JS frontend for Torch.
----------------------------------------------------------------------

require 'os'
require 'io'
require 'sys'
require 'paths'

webterm = {}

----------------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------------
if not sys.execute('which node'):find('node') then
   print('<webterm> could not find node: webterm requires node.js')
   print('  + please install:')
   print('     - node.js (http://nodejs.org/)')
   print('     - node package: express')
   print('     - node package: stripcolorcodes')
   print('  + once node.js is installed, extra packages can be installed')
   print('    easily with npm:')
   print('     - npm install express stripcolorcodes')
   os.exit()
end

----------------------------------------------------------------------
-- Server Root
----------------------------------------------------------------------
webterm.root = torch.packageLuaPath('webterm')

----------------------------------------------------------------------
-- Server
----------------------------------------------------------------------
function webterm.server(port)
   local currentpath = paths.cwd()
   port = port or '8080'
   if sys.OS == 'macos' then
      os.execute('sleep 1 && open http://localhost:' .. port .. '/ &')
   end
   os.execute('cd ' .. webterm.root .. '; '
              .. 'node server.js ' .. port .. ' ' .. currentpath)
end

----------------------------------------------------------------------
-- Run Server (only if in bare environment)
----------------------------------------------------------------------
if not _kernel_ then
   webterm.server()
end

----------------------------------------------------------------------
-- General Inliner
----------------------------------------------------------------------
function webterm.show(data)
   if torch.typename(data) and torch.typename(data):find('torch.*Tensor') and (data:dim() == 2 or data:dim() == 3) then
      local file = os.tmpname() .. '.jpg'
      local fullpath = webterm.root..file
      os.execute('mkdir -p ' .. paths.dirname(fullpath))
      image.save(fullpath, data)
      print('<img src="'..file..'" />')
   elseif type(data) == 'string' then
      print('<img src="'..data..'" />')
   else
      print('<webterm> cannot inline this kind of data')
   end
end

----------------------------------------------------------------------
-- Plot Inliner
----------------------------------------------------------------------
function webterm.plot(...)
   local file = os.tmpname() .. '.jpg'
   local fullpath = webterm.root..file
   os.execute('mkdir -p ' .. paths.dirname(fullpath))
   gnuplot.pngfigure(fullpath)
   gnuplot.plot(...)
   gnuplot.plotflush()
   sys.sleep(0.5)
   webterm.show(file)
end

----------------------------------------------------------------------
-- Hist Inliner
----------------------------------------------------------------------
function webterm.hist(...)
   local file = os.tmpname() .. '.jpg'
   local fullpath = webterm.root..file
   os.execute('mkdir -p ' .. paths.dirname(fullpath))
   gnuplot.pngfigure(fullpath)
   gnuplot.hist(...)
   gnuplot.plotflush()
   sys.sleep(0.5)
   webterm.show(file)
end


----------------------------------------------------------------------
-- Image Inliner
----------------------------------------------------------------------
function webterm.display(...)
      -- usage
   local _, input, zoom, min, max, legend, w, ox, oy, scaleeach, gui, offscreen, padding, symm, nrow, saturate = dok.unpack(
      {...},
      'image.display',
      'displays a single image, with optional saturation/zoom',
      {arg='image', type='torch.Tensor | table', help='image (HxW or KxHxW or Kx3xHxW or list)', req=true},
      {arg='zoom', type='number', help='display zoom', default=1},
      {arg='min', type='number', help='lower-bound for range'},
      {arg='max', type='number', help='upper-bound for range'},
      {arg='legend', type='string', help='legend', default='image.display'},
      {arg='win', type='qt window', help='window descriptor'},
      {arg='x', type='number', help='x offset (only if win is given)', default=0},
      {arg='y', type='number', help='y offset (only if win is given)', default=0},
      {arg='scaleeach', type='boolean', help='individual scaling for list of images', default=false},
      {arg='gui', type='boolean', help='if on, user can zoom in/out (turn off for faster display)',
       default=true},
      {arg='offscreen', type='boolean', help='offscreen rendering (to generate images)',
       default=false},
      {arg='padding', type='number', help='number of padding pixels between images', default=0},
      {arg='symmetric',type='boolean',help='if on, images will be displayed using a symmetric dynamic range, useful for drawing filters', default=false},
      {arg='nrow',type='number',help='number of images per row', default=6},
      {arg='saturate', type='boolean', help='saturate (useful when min/max are lower than actual min/max', default=true}
   )
   offscreen = true
   local win = image.display(input, zoom, min, max, legend, w, ox, oy, scaleeach, gui, offscreen, padding, symm, nrow, saturate)
   local img = win:image():toTensor()
   webterm.show(img)
end
