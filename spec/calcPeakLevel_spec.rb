#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2012 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/calcPeakLevel'

# maximum volume for 16-bit audio is 96 decibel
describe CalcPeakLevel do
  
  let (:exec) {double('Execute').as_null_object}
  let (:deps) {double('Dependeny').as_null_object}
  let (:prefs) {double('Preferences::Main').as_null_object}
  let (:calc) {CalcPeakLevel.new(exec, deps, prefs)}
   
  context "Given sox is installed" do
    before(:each) do
      deps.stub!(:installed?).with('sox').and_return true
    end
    
    # calculation is (96 + sox-level) / 96 * 100
    it "should report 93.75 percent if the peak level db from sox is -6.00" do
      sox_output = ["Pk lev dB      -6.00     -6.00     -6.45"]
      exec.should_receive(:launch).with("sox \"filename\" -n stats", false, true).and_return sox_output      
      calc.getPeakLevel('filename').should == '93.75'
    end
    
    it "should report 100% if the peak level db from sox is 0" do
      sox_output = ["Pk lev dB       0.00      0.00      0.00", 'blabla']
      exec.should_receive(:launch).with("sox \"filename\" -n stats", false, true).and_return sox_output      
      calc.getPeakLevel('filename').should == '100.00'
    end
  end
end