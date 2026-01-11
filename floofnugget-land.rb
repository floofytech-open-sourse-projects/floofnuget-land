require "json"

# ============================================
#   FLOOFNUGET-LAND — REAL TIME EDITION
#   Title Screen + JSON Save/Load + Dream Biomes
# ============================================

class Game
  attr_reader :current_room, :inventory, :mood, :hunger, :energy

  def initialize
    @rooms = {}
    build_world

    @current_room = @rooms[:living_room]
    @inventory = []
    @mood = 6
    @hunger = 3
    @energy = 7

    @game_over = false
  end

  # --------------------------------------------
  # WORLD BUILDING
  # --------------------------------------------

  def build_world
    @rooms[:living_room] = Room.new(
      :living_room,
      "Living Room",
      "The heart of Floofnuget-Land: couches, blankets, and a prime sunbeam patch.",
      {
        "north" => :kitchen,
        "east"  => :front_yard,
        "west"  => :hallway
      },
      ["squeaky toy"]
    )

    @rooms[:kitchen] = Room.new(
      :kitchen,
      "Kitchen",
      "The sacred temple of food. Bowls, crumbs, and The Fridge of Infinite Smells.",
      {
        "south" => :living_room
      },
      ["water bowl"]
    )

    @rooms[:front_yard] = Room.new(
      :front_yard,
      "Front Yard",
      "The public-facing border of Floofnuget-Land. Grass, mail carriers, and mysterious passerby shoes.",
      {
        "west" => :living_room,
        "east" => :sidewalk
      },
      ["stick"]
    )

    @rooms[:sidewalk] = Room.new(
      :sidewalk,
      "Sidewalk",
      "The Great Gray River where all neighborhood smells eventually drift.",
      {
        "west" => :front_yard
      },
      []
    )

    @rooms[:hallway] = Room.new(
      :hallway,
      "Hallway",
      "A narrow corridor of doors and dust bunnies. Secret hooman stuff lives here.",
      {
        "east"  => :living_room,
        "north" => :bedroom,
        "south" => :backyard
      },
      []
    )

    @rooms[:bedroom] = Room.new(
      :bedroom,
      "Bedroom",
      "The Big Bed of Floofnuget-Land. Pillow Fort. Snuggle HQ.",
      {
        "south" => :hallway
      },
      ["treat (hidden)"]
    )

    @rooms[:backyard] = Room.new(
      :backyard,
      "Backyard",
      "The Zoomie Arena of Floofnuget-Land. Fence, grass, and squirrel politics.",
      {
        "north" => :hallway
      },
      ["buried bone"]
    )
  end

  # --------------------------------------------
  # TITLE SCREEN
  # --------------------------------------------

  def title_screen
    loop do
      system("clear") rescue nil
      puts "====================================="
      puts "           FLOOFNUGET-LAND"
      puts "====================================="
      puts
      puts " 1) Load Save"
      puts " 2) Play"
      puts " 3) Description"
      puts " 4) Quit"
      puts
      print "> "

      choice = $stdin.gets.to_s.strip

      case choice
      when "1"
        title_load_menu
        return
      when "2"
        return
      when "3"
        dog_description_screen
      when "4"
        exit
      else
        puts "Invalid choice."
        sleep 1
      end
    end
  end

  def dog_description_screen
    system("clear") rescue nil
    puts "====================================="
    puts "      WHAT IS FLOOFNUGET-LAND?"
    puts "====================================="
    puts
    puts "You are a dog."
    puts "A good dog."
    puts "A floofy, wiggly, snack-seeking, zoomie-capable creature"
    puts "living your best life in a world of:"
    puts
    puts " • Sunbeams"
    puts " • Squirrels with attitudes"
    puts " • Mysterious hooman noises"
    puts " • Forbidden trash treasures"
    puts " • The Big Bed (holy site)"
    puts
    puts "Your mission:"
    puts "  Be the best floof you can be."
    puts
    puts "Press ENTER to return."
    $stdin.gets
  end

  def title_load_menu
    system("clear") rescue nil
    puts "====================================="
    puts "            LOAD SAVE"
    puts "====================================="
    puts "Choose slot (1–14):"
    print "> "
    slot = $stdin.gets.to_i
    load_game(slot)
  end

  # --------------------------------------------
  # MAIN LOOP
  # --------------------------------------------

  def start
    title_screen
    intro

    until @game_over
      show_status
      print "\n> "
      input = $stdin.gets
      break unless input
      handle_command(input.chomp.strip.downcase)
      trigger_random_events unless @game_over
    end

    outro
  end

  # --------------------------------------------
  # INTRO / OUTRO
  # --------------------------------------------

  def intro
    puts <<~INTRO
      Welcome to Floofnuget-Land.

      You are a perfectly normal dog living your perfectly normal dog life:
        - a house to patrol
        - humans to interpret
        - smells to decode
        - and a whole day to be the best floof you can be.

      Commands:
        look, sniff, bark, nap, eat, drink, zoomies
        go north/south/east/west
        take <item>, drop <item>, inventory
        save, load
        help, quit
    INTRO
  end

  def outro
    puts "\nYour Floofnuget-Land day fades into a warm blur of naps and snacks."
    puts "Thanks for playing."
  end

  # --------------------------------------------
  # REAL TIME SYSTEM
  # --------------------------------------------

  def update_real_time
    now = Time.now
    @time_hour = now.hour
    @time_min  = now.min
  end

  def time_label
    case @time_hour
    when 5..11 then "Morning (#{fmt_time})"
    when 12..16 then "Afternoon (#{fmt_time})"
    when 17..20 then "Evening (#{fmt_time})"
    else "Night (#{fmt_time})"
    end
  end

  def fmt_time
    "#{@time_hour}:#{@time_min.to_s.rjust(2, '0')}"
  end

  # --------------------------------------------
  # STATUS DISPLAY
  # --------------------------------------------

  def show_status
    update_real_time

    puts "\n=== #{current_room.name} ==="
    puts current_room.description
    puts
    puts "Exits: #{current_room.exits.keys.join(', ')}" unless current_room.exits.empty?
    puts "Things: #{current_room.items.join(', ')}" unless current_room.items.empty?

    puts
    puts "Mood:   #{bar(@mood, 10)} (#{@mood}/10)"
    puts "Hunger: #{bar(@hunger, 10)} (#{@hunger}/10)"
    puts "Energy: #{bar(@energy, 10)} (#{@energy}/10)"
    puts "Time:   #{time_label}"
  end

  def bar(value, max)
    value = [[value, 0].max, max].min
    "#" * value + "-" * (max - value)
  end

  # --------------------------------------------
  # COMMAND HANDLING
  # --------------------------------------------

  def handle_command(input)
    return if input.empty?

    words = input.split
    verb  = words.first
    rest  = words[1..]&.join(" ")

    case verb
    when "go", "walk", "run"
      move(rest)
    when "look"
      handle_look
    when "sniff"
      handle_sniff
    when "bark"
      handle_bark(rest)
    when "nap", "sleep"
      handle_nap
    when "eat"
      handle_eat
    when "drink", "lap"
      handle_drink
    when "zoomies"
      handle_zoomies
    when "inventory"
      handle_inventory
    when "take"
      handle_take(rest)
    when "drop"
      handle_drop(rest)
    when "save"
      puts "Choose slot (1–14):"
      slot = $stdin.gets.to_i
      save_game(slot)
    when "load"
      puts "Choose slot (1–14):"
      slot = $stdin.gets.to_i
      load_game(slot)
    when "help"
      handle_help
    when "quit", "exit"
      @game_over = true
    else
      puts "You tilt your head. You don't know how to '#{input}'."
    end

    check_end_conditions
  end

  # --------------------------------------------
  # ACTIONS
  # --------------------------------------------

  def move(direction)
    if direction.nil?
      puts "Go where?"
      return
    end

    dir = normalize_direction(direction)
    unless dir
      puts "You spin in a confused circle."
      return
    end

    dest = current_room.exits[dir]
    if dest.nil?
      puts "You bump into invisible Floofnuget-Land boundaries."
      return
    end

    @current_room = @rooms[dest]
    @energy -= 1
    @hunger += 1
    @mood += 1 if rand < 0.3
    clamp_stats

    puts "You trot #{dir}."
  end

  def handle_look
    puts current_room.description
    puts "You see: #{current_room.items.join(', ')}" unless current_room.items.empty?
  end

  def handle_sniff
    @mood += 1
    @hunger += 0.5
    clamp_stats

    case current_room.key
    when :kitchen
      puts "You sniff… FOOD. Ancient crumbs whisper secrets of past snacks."
    when :backyard
      puts "You sniff 47 pee-mails and 3 squirrel conspiracies."
    when :front_yard
      puts "You sniff the wind. Distant dogs report their findings."
    when :bedroom
      puts "You sniff the Big Bed. It smells like dreams and hooman laundry."
    else
      puts "You sniff deeply. Floofnuget-Land is rich with stories."
    end
  end

  def handle_bark(target)
    target ||= "the void"
    @energy -= 1
    clamp_stats

    if [:front_yard, :backyard].include?(current_room.key)
      puts "You bark at #{target}. A distant neighborhood dog replies."
      @mood += 1
    else
      puts "You bark at #{target}. A human calls from another room: 'Hey, everything okay?'"
      @mood -= 1
    end
    clamp_stats
  end

  def handle_nap
    if @energy >= 9
      puts "You try to nap but you are too wiggly. You turn in a circle and give up."
      @mood -= 1
    else
      puts "You curl up and drift into sleep..."
      @energy += 4
      @hunger += 1
      @mood += 1
      clamp_stats

      dream_sequence if rand < 0.4
    end
  end

  def handle_eat
    if current_room.key == :kitchen
      puts "You devour your food with appropriate floof intensity."
      @hunger -= 4
      @mood += 2
    elsif inventory_include?("buried bone")
      puts "You gnaw your special buried bone. Legendary flavor."
      @hunger -= 2
      @mood += 2
    else
      puts "You see no food to eat here."
    end
    clamp_stats
  end

  def handle_drink
    if current_room.key == :kitchen
      puts "You slurp water loudly from your bowl."
      @hunger -= 0.5
      @mood += 1
    else
      puts "No water here. You lick your nose instead."
    end
    clamp_stats
  end

  def handle_zoomies
    if @energy < 3
      puts "You dream of zoomies but your legs are jelly. You flop dramatically."
      @mood -= 1
    else
      puts "You unleash MAXIMUM FLOOF ZOOMIES."
      @energy -= 3
      @hunger += 2
      @mood += 2
      if current_room.key == :backyard && rand < 0.5
        puts "A squirrel flees up a tree, deeply offended by your speed."
      end
    end
    clamp_stats
  end

  def handle_inventory
    if @inventory.empty?
      puts "You carry nothing but vibes and fur."
    else
      puts "You have: #{@inventory.join(', ')}"
    end
  end

  def handle_take(item_name)
    if item_name.nil?
      puts "Take what?"
      return
    end

    item = fuzzy_find(current_room.items, item_name)
    if item.nil?
      puts "You don't see that here."
      return
    end

    current_room.items.delete(item)
    @inventory << item
    puts "You pick up the #{item}."
    @mood += 1
    clamp_stats
  end

  def handle_drop(item_name)
    if item_name.nil?
      puts "Drop what?"
      return
    end

    item = fuzzy_find(@inventory, item_name)
    if item.nil?
      puts "You don't have that."
      return
    end

    @inventory.delete(item)
    current_room.items << item
    puts "You drop the #{item}."
    @mood -= 0.5
    clamp_stats
  end

  def handle_help
    puts <<~HELP
      You are a normal dog in Floofnuget-Land.

      Commands:
        look              : describe where you are
        go <dir>          : move (north, south, east, west)
        sniff             : investigate smells
        bark [at thing]   : express opinions
        nap / sleep       : regain energy (sometimes enters dreams)
        eat               : eat from bowl (kitchen) or bone (if carried)
        drink / lap       : drink from water bowl (kitchen)
        zoomies           : unleash chaotic floof energy
        take <item>       : pick something up
        drop <item>       : drop something
        inventory         : see what you're carrying
        save              : save game to slot 1–14
        load              : load game from slot 1–14
        help              : show this help
        quit              : end the session
    HELP
  end

  # --------------------------------------------
  # DREAM SYSTEM (BIOME SELECTION + 20-TURN LIMIT)
  # --------------------------------------------

  def dream_sequence
    biome = choose_dream_biome
    run_dream_biome(biome)
  end

  def choose_dream_biome
    loop do
      system("clear") rescue nil
      puts "====================================="
      puts "         DREAM BIOME SELECT"
      puts "====================================="
      puts
      puts " 1) Forest Dream"
      puts " 2) Night Alley Dream"
      puts " 3) Snow Dream"
      puts " 4) Chaos Dream"
      puts
      print "> "

      choice = $stdin.gets.to_s.strip

      case choice
      when "1" then return :forest
      when "2" then return :alley
      when "3" then return :snow
      when "4" then return :chaos
      else
        puts "Invalid choice."
        sleep 1
      end
    end
  end

  def run_dream_biome(biome)
    system("clear") rescue nil
    puts "You drift into a dream..."
    sleep 1

    dream_map = generate_dream_map(biome)
    player_x, player_y = find_player(dream_map)
    squirrels = find_squirrels(dream_map)

    turns_left = 20

    loop do
      system("clear") rescue nil
      puts "=== DREAM REALM (#{biome.to_s.capitalize}) ==="
      puts "Move with h/j/k/l or 'left/right/up/down'"
      puts "Chase the squirrels (&)!"
      puts "Turns left: #{turns_left}"
      puts

      dream_map.each { |row| puts row }

      break if squirrels.empty?
      break if turns_left <= 0

      print "> "
      input = $stdin.gets.to_s.strip

      dx = 0
      dy = 0

      case input
      when "h", "left"  then dx = -1
      when "l", "right" then dx = 1
      when "k", "up"    then dy = -1
      when "j", "down"  then dy = 1
      when "q"          then break
      else
        next
      end

      new_x = player_x + dx
      new_y = player_y + dy

      next if dream_map[new_y][new_x] == "#"

      if dream_map[new_y][new_x] == "&"
        puts "You pounce on a dream-squirrel!"
        squirrels.delete([new_x, new_y])
        sleep 0.4
      end

      dream_map[player_y][player_x] = biome_floor(biome)
      player_x = new_x
      player_y = new_y
      dream_map[player_y][player_x] = "@"

      turns_left -= 1
    end

    if turns_left <= 0
      puts "\nThe dream dissolves suddenly... WAKEY WAKEY!"
    elsif squirrels.empty?
      puts "\nYou caught all the dream-squirrels!"
    else
      puts "\nYou leave the dream early."
    end

    sleep 1
    puts "You wake up feeling strangely powerful."
    @mood += 2
    clamp_stats
  end

  def generate_dream_map(biome)
    case biome
    when :forest
      [
        "###########",
        "#@..^..&..#",
        "#..^^.^...#",
        "#..&..^^..#",
        "#...^..&..#",
        "#..^....^.#",
        "###########"
      ]
    when :alley
      [
        "###########",
        "#@..t..&..#",
        "#..t.t....#",
        "#....&..t.#",
        "#..t....&.#",
        "#....t....#",
        "###########"
      ]
    when :snow
      [
        "###########",
        "#@..*..&..#",
        "#..**.*...#",
        "#..&..**..#",
        "#...*..&..#",
        "#..*....*.#",
        "###########"
      ]
    when :chaos
      [
        "###########",
        "#@..~..&..#",
        "#..~.~....#",
        "#.&..~..&.#",
        "#..~....~.#",
        "#.&..~....#",
        "###########"
      ]
    else
      [
        "###########",
        "#@.......&#",
        "#.........#",
        "#....&....#",
        "#.........#",
        "#&........#",
        "###########"
      ]
    end
  end

  def find_player(dream_map)
    dream_map.each_with_index do |row, y|
      x = row.index("@")
      return [x, y] if x
    end
    [1, 1]
  end

  def find_squirrels(dream_map)
    squirrels = []
    dream_map.each_with_index do |row, y|
      row.chars.each_with_index do |c, x|
        squirrels << [x, y] if c == "&"
      end
    end
    squirrels
  end

  def biome_floor(biome)
    case biome
    when :forest then "."
    when :alley  then "."
    when :snow   then "."
    when :chaos  then "."
    else "."
    end
  end

  # --------------------------------------------
  # RANDOM EVENTS (REAL TIME)
  # --------------------------------------------

  def trigger_random_events
    snuggle_event if rand < snuggle_chance
    walk_event if rand < walk_chance
  end

  def snuggle_chance
    base = 0.03
    base += 0.05 if [:bedroom, :living_room].include?(current_room.key)
    base += 0.06 if @time_hour >= 20 || @time_hour <= 7
    base
  end

  def snuggle_event
    puts "\nA human pats the couch and says your name softly. SNUGGLE TIME!"
    @mood += 3
    @energy += 2
    @hunger += 1
    clamp_stats
  end

  def walk_chance
    base = 0.02
    base += 0.05 if (7..10).include?(@time_hour)
    base += 0.05 if (17..20).include?(@time_hour)
    base
  end

  def walk_event
    puts "\nYou hear the jingle of a leash. WALK TIME!"
    @mood += 3
    @energy -= 2
    @hunger += 2

    case rand(3)
    when 0
      puts "You find a PERFECT new stick."
      @inventory << "stick" unless inventory_include?("stick")
    when 1
      puts "You meet another dog and exchange sniff-data."
    when 2
      puts "You chase a squirrel and nearly achieve orbit."
      @mood += 1
    end

    clamp_stats
  end

  # --------------------------------------------
  # JSON SAVE / LOAD SYSTEM
  # --------------------------------------------

  def save_game(slot)
    data = {
      room: @current_room.key,
      inventory: @inventory,
      mood: @mood,
      hunger: @hunger,
      energy: @energy
    }

    File.write("save#{slot}.json", JSON.pretty_generate(data))
    puts "Saved to slot #{slot}."
  end

  def load_game(slot)
    file = "save#{slot}.json"
    unless File.exist?(file)
      puts "Save slot #{slot} is empty."
      return
    end

    data = JSON.parse(File.read(file), symbolize_names: true)

    @current_room = @rooms[data[:room]]
    @inventory = data[:inventory]
    @mood = data[:mood]
    @hunger = data[:hunger]
    @energy = data[:energy]

    puts "Loaded save slot #{slot}."
  end

  # --------------------------------------------
  # END CONDITIONS
  # --------------------------------------------

  def check_end_conditions
    if @hunger >= 10
      puts "\nYour stomach rumbles louder than any bark. The day ends in hunger."
      @game_over = true
    elsif @mood <= 0
      puts "\nYou curl up, overwhelmed. Tomorrow will be better."
      @game_over = true
    elsif @energy <= 0
      puts "\nYou drop where you stand and fall into deep sleep. Day over."
      @game_over = true
    end
  end

  # --------------------------------------------
  # HELPERS
  # --------------------------------------------

  def normalize_direction(direction)
    case direction[0]
    when "n" then "north"
    when "s" then "south"
    when "e" then "east"
    when "w" then "west"
    else nil
    end
  end

  def fuzzy_find(collection, name)
    down = name.downcase
    collection.find { |i| i.downcase.include?(down) }
  end

  def inventory_include?(name)
    @inventory.any? { |i| i.downcase.include?(name.downcase) }
  end

  def clamp_stats
    @mood   = [[@mood,   0].max, 10].min
    @hunger = [[@hunger, 0].max, 10].min
    @energy = [[@energy, 0].max, 10].min
  end

  # --------------------------------------------
  # ROOM CLASS
  # --------------------------------------------

  class Room
    attr_reader :key, :name, :description, :exits, :items

    def initialize(key, name, description, exits, items)
      @key = key
      @name = name
      @description = description
      @exits = exits
      @items = items
    end
  end
end

# --------------------------------------------
# RUN GAME
# --------------------------------------------

if __FILE__ == $0
  Game.new.start
end

