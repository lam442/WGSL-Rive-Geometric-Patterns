type StarPattern = {
  points: Input<number>,
  outerRadius: Input<number>,
  innerRadius: Input<number>,
  cornerRadius: Input<number>,
  rotation: Input<number>,
  spacingX: Input<number>,
  spacingY: Input<number>,
  stagger: Input<number>,
  canvasWidth: Input<number>,
  canvasHeight: Input<number>,
  starColor: Input<Color>,

  canvas: GPUCanvas?,
  pipeline: GPUPipeline?,
  ubo: GPUBuffer?,
  bindGroup: GPUBindGroup?,
  staging: buffer,
  sampler: ImageSampler,
}

local function uploadUniforms(self: StarPattern)
  local ubo = self.ubo
  if not ubo then
    return
  end

  local s = self.staging
  buffer.writef32(s, 0, self.points)
  buffer.writef32(s, 4, self.outerRadius)
  buffer.writef32(s, 8, self.innerRadius)
  buffer.writef32(s, 12, self.cornerRadius)
  buffer.writef32(s, 16, self.rotation)
  buffer.writef32(s, 20, self.spacingX)
  buffer.writef32(s, 24, self.spacingY)
  buffer.writef32(s, 28, self.stagger)

  local sc = Color.toFloat(self.starColor)
  buffer.writef32(s, 32, sc[1])
  buffer.writef32(s, 36, sc[2])
  buffer.writef32(s, 40, sc[3])
  buffer.writef32(s, 44, sc[4])

  ubo:write(s)
end

function init(self: StarPattern, context: Context): boolean
  local shader = context:shader('StarPatternShader')
  if not shader then
    print('StarPatternShader not found!')
    return false
  end

  local w = math.max(1, math.floor(self.canvasWidth))
  local h = math.max(1, math.floor(self.canvasHeight))
  local canvas = context:gpuCanvas({ width = w, height = h })

  local pipeline = GPUPipeline.new({
    vertex = shader,
    fragment = shader,
    vertexLayout = {},
    colorTargets = {
      { format = canvas.format },
    },
  })

  local ubo = GPUBuffer.new({
    size = 48,
    usage = 'uniform',
  })

  local bindGroup = GPUBindGroup.new({
    layout = pipeline:getBindGroupLayout(0),
    ubos = {
      { slot = 0, buffer = ubo },
    },
  })

  self.canvas = canvas
  self.pipeline = pipeline
  self.ubo = ubo
  self.bindGroup = bindGroup

  uploadUniforms(self)
  return true
end

function update(self: StarPattern)
  local canvas = self.canvas
  if canvas then
    local w = math.max(1, math.floor(self.canvasWidth))
    local h = math.max(1, math.floor(self.canvasHeight))
    if canvas.width ~= w or canvas.height ~= h then
      canvas:resize(w, h)
    end
  end
  uploadUniforms(self)
end

function draw(self: StarPattern, renderer: Renderer)
  local canvas = self.canvas
  local pipeline = self.pipeline
  local bindGroup = self.bindGroup

  if not canvas or not pipeline or not bindGroup then
    return
  end

  local pass = canvas:beginRenderPass({
    color = {
      {
        loadOp = 'clear',
        storeOp = 'store',
        clearColor = { 0, 0, 0, 0 },
      },
    },
  })

  pass:setPipeline(pipeline)
  pass:setBindGroup(0, bindGroup)
  pass:draw(3)
  pass:finish()

  renderer:drawImage(canvas.image, self.sampler, 'srcOver', 1)
end

return function(): Node<StarPattern>
  return {
    points = 5,
    outerRadius = 10,
    innerRadius = 4.5,
    cornerRadius = 0,
    rotation = 0,
    spacingX = 32,
    spacingY = 32,
    stagger = 0,
    canvasWidth = 800,
    canvasHeight = 800,
    starColor = Color.rgba(0, 0, 0, 255),
    canvas = nil,
    pipeline = nil,
    ubo = nil,
    bindGroup = nil,
    staging = buffer.create(48),
    sampler = ImageSampler('clamp', 'clamp', 'bilinear'),
    init = init,
    update = update,
    draw = draw,
  }
end
